//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Factory
import Foundation
import Get
import JellyfinAPI
import KeychainSwift
import OrderedCollections
import SwiftUI

// TODO: instead of just signing in duplicate user, send event for alert
//       to override existing user access token?
//       - won't require deleting and re-signing in user for password changes
//       - account for local device auth required
// TODO: ignore NSURLErrorDomain Code=-999 cancelled error on sign in
//       - need to make NSError wrappres anyways

// Note: UserDto in StoredValues so that it doesn't need to be passed
//       around along with the user UserState. Was just easy

final class UserSignInViewModel: ViewModel, Eventful, Stateful {

    // MARK: Event

    enum Event {
        case duplicateUser(UserState)
        case error(JellyfinAPIError)
        case signedIn(UserState)
    }

    // MARK: Action

    enum Action: Equatable {
        case getPublicData
        case signIn(username: String, password: String, policy: UserAccessPolicy)
        case signInDuplicate(UserState, replace: Bool)
        case signInQuickConnect(secret: String, policy: UserAccessPolicy)
        case cancel
    }

    enum BackgroundState: Hashable {
        case gettingPublicData
    }

    // MARK: State

    enum State: Hashable {
        case initial
        case signingIn
    }

    @Published
    var backgroundStates: OrderedSet<BackgroundState> = []
    @Published
    var isQuickConnectEnabled = false
    @Published
    var publicUsers: [UserDto] = []
    @Published
    var serverDisclaimer: String? = nil
    @Published
    var state: State = .initial

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    let quickConnect: QuickConnect
    let server: ServerState

    private var eventSubject: PassthroughSubject<Event, Never> = .init()
    private var signInTask: AnyCancellable?

    init(server: ServerState) {
        self.server = server
        self.quickConnect = QuickConnect(client: server.client)

        super.init()

        quickConnect.$state
            .sink { [weak self] state in
                if case let QuickConnect.State.authenticated(secret: secret) = state {
                    guard let self else { return }

                    Task {
                        await self.send(.signInQuickConnect(secret: secret, policy: StoredValues[.Temp.userAccessPolicy]))
                    }
                }
            }
            .store(in: &cancellables)
    }

    func respond(to action: Action) -> State {
        switch action {
        case .getPublicData:
            Task { [weak self] in
                do {

                    await MainActor.run {
                        let _ = self?.backgroundStates.append(.gettingPublicData)
                    }

                    let isQuickConnectEnabled = try await self?.retrieveQuickConnectEnabled()
                    let publicUsers = try await self?.retrievePublicUsers()
                    let serverMessage = try await self?.retrieveServerDisclaimer()

                    guard let self else { return }

                    await MainActor.run {
                        self.backgroundStates.remove(.gettingPublicData)
                        self.isQuickConnectEnabled = isQuickConnectEnabled ?? false
                        self.publicUsers = publicUsers ?? []
                        self.serverDisclaimer = serverMessage
                    }
                } catch {
                    self?.backgroundStates.remove(.gettingPublicData)
                }
            }
            .store(in: &cancellables)

            return state
        case let .signIn(username, password, policy):
            signInTask?.cancel()

            signInTask = Task {
                do {
                    let authentication = try await makeSignInRequest(username: username, password: password)

                    guard let userData = authentication.user,
                          let id = userData.id
                    else {
                        logger.critical("Missing user data from network call")
                        throw JellyfinAPIError("An internal error has occurred")
                    }

                    // UserState.accessToken setter persists changes to the keychain automatically.
                    // Need to check if UserState exists before setting new accessToken.
                    if let existingUser = getExistingUser(userId: id) {
                        try await handleExistingUser(user: existingUser, authentication: authentication, policy: policy)
                    } else {
                        try await handleNewUser(authentication: authentication, policy: policy)
                    }

                    await MainActor.run {
                        self.state = .initial
                    }
                } catch is CancellationError {
                    // cancel doesn't matter
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                        self.state = .initial
                    }
                }
            }
            .asAnyCancellable()

            return .signingIn
        case let .signInDuplicate(duplicateUser, replace):
            if replace {
                setNewAccessToken(user: duplicateUser)
            } else {
                // just need the id, even though this has a different
                // access token than stored
                eventSubject.send(.signedIn(duplicateUser))
            }

            return state
        case let .signInQuickConnect(secret, policy):
            signInTask?.cancel()

            signInTask = Task {
                do {
                    let authentication = try await server.client.signIn(quickConnectSecret: secret)

                    guard let userData = authentication.user,
                          let id = userData.id
                    else {
                        logger.critical("Missing user data from network call")
                        throw JellyfinAPIError("An internal error has occurred")
                    }

                    if let existingUser = getExistingUser(userId: id) {
                        try await handleExistingUser(user: existingUser, authentication: authentication, policy: policy)
                    } else {
                        try await handleNewUser(authentication: authentication, policy: policy)
                    }
                } catch is CancellationError {
                    // cancel doesn't matter
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                        self.state = .initial
                    }
                }
            }
            .asAnyCancellable()

            return .signingIn
        case .cancel:
            signInTask?.cancel()

            return .initial
        }
    }

    private func makeSignInRequest(username: String, password: String) async throws -> AuthenticationResult {
        let username = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .objectReplacement)

        let password = password
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .objectReplacement)

        return try await server.client.signIn(username: username, password: password)
    }

    private func createUserState(authentication: AuthenticationResult, policy: UserAccessPolicy) throws -> UserState {

        guard let accessToken = authentication.accessToken,
              let userData = authentication.user,
              let id = userData.id,
              let username = userData.name
        else {
            logger.critical("Missing user data from network call")
            throw JellyfinAPIError("An internal error has occurred")
        }

        StoredValues[.Temp.userData] = userData
        StoredValues[.Temp.userAccessPolicy] = policy

        let newState = UserState(
            id: id,
            serverID: server.id,
            username: username
        )

        newState.accessToken = accessToken

        return newState
    }

    private func updateUserState(user: UserState, authentication: AuthenticationResult, policy: UserAccessPolicy) throws {

        guard let accessToken = authentication.accessToken,
              let userData = authentication.user
        else {
            logger.critical("Missing user data from network call")
            throw JellyfinAPIError("An internal error has occurred")
        }

        StoredValues[.Temp.userData] = userData
        StoredValues[.Temp.userAccessPolicy] = policy

        user.accessToken = accessToken
    }

    private func getExistingUser(userId: String) -> UserState? {
        let existingUser = try? SwiftfinStore
            .dataStack
            .fetchOne(From<UserModel>().where(\.$id == userId))
        return existingUser?.state
    }

    private func shouldReauthenticate(userId: String) -> Bool {
        guard let existingUser = getExistingUser(userId: userId) else {
            return false
        }

        return existingUser.accessToken == ""
    }

    private func handleExistingUser(user: UserState, authentication: AuthenticationResult, policy: UserAccessPolicy) async throws {
        // If accessToken was previously cleared, update UserState
        if shouldReauthenticate(userId: user.id) {
            try updateUserState(user: user, authentication: authentication, policy: policy)

            await MainActor.run {
                self.state = .initial
                self.eventSubject.send(.signedIn(user))
            }
        } else {
            // TODO: Address duplicate user case
            await MainActor.run {
                // user has same id, but new access token
                self.state = .initial
                self.eventSubject.send(.duplicateUser(user))
            }
        }
    }

    private func handleNewUser(authentication: AuthenticationResult, policy: UserAccessPolicy) async throws {
        let newUser = try createUserState(authentication: authentication, policy: policy)
        try await save(user: newUser)

        await MainActor.run {
            self.state = .initial
            self.eventSubject.send(.signedIn(newUser))
        }
    }

    @MainActor
    private func save(user: UserState) async throws {

        guard let serverModel = try? dataStack.fetchOne(From<ServerModel>().where(\.$id == server.id)) else {
            logger.critical("Unable to find server to save user")
            throw JellyfinAPIError("An internal error has occurred")
        }

        let user = try dataStack.perform { transaction in
            let newUser = transaction.create(Into<UserModel>())

            newUser.id = user.id
            newUser.username = user.username

            let editServer = transaction.edit(serverModel)!
            editServer.users.insert(newUser)

            return newUser.state
        }

        user.data = StoredValues[.Temp.userData]
        user.accessPolicy = StoredValues[.Temp.userAccessPolicy]

        keychain.set(StoredValues[.Temp.userLocalPin], forKey: "\(user.id)-pin")
        user.pinHint = StoredValues[.Temp.userLocalPinHint]

        // TODO: remove when implemented periodic cleanup elsewhere
        StoredValues[.Temp.userAccessPolicy] = .none
        StoredValues[.Temp.userLocalPin] = ""
        StoredValues[.Temp.userLocalPinHint] = ""
    }

    private func retrievePublicUsers() async throws -> [UserDto] {
        let request = Paths.getPublicUsers
        let response = try await server.client.send(request)

        return response.value
    }

    private func retrieveServerDisclaimer() async throws -> String? {
        let request = Paths.getBrandingOptions
        let response = try await server.client.send(request)

        guard let disclaimer = response.value.loginDisclaimer, disclaimer.isNotEmpty else { return nil }

        return disclaimer
    }

    private func retrieveQuickConnectEnabled() async throws -> Bool {
        let request = Paths.getEnabled
        let response = try await server.client.send(request)

        let isEnabled = try? JSONDecoder().decode(Bool.self, from: response.value)
        return isEnabled ?? false
    }

    // server has same id, but new access token
    private func setNewAccessToken(user: UserState) {
        do {
            guard let existingUser = try dataStack.fetchOne(From<UserModel>().where(\.$id == user.id)) else { return }
            existingUser.state.accessToken = user.accessToken

            eventSubject.send(.signedIn(existingUser.state))
        } catch {
            logger.critical("\(error.localizedDescription)")
        }
    }
}
