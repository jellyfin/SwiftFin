//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Defaults
import Factory
import Foundation
import JellyfinAPI
import OrderedCollections

class SelectUserViewModel: ViewModel, Eventful, Stateful {

    // MARK: Event

    enum Event {
        case error(JellyfinAPIError)
    }

    // MARK: Action

    enum Action: Equatable {
        case deleteUsers([UserState])
        case getServers
        case signIn(UserState)
    }

    // MARK: State

    enum State: Hashable {
        case content
    }

    @Published
    var servers: OrderedDictionary<ServerState, [UserState]> = [:]
    @Published
    var state: State = .content

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    @MainActor
    func respond(to action: Action) -> State {
        switch action {
        case let .deleteUsers(users):
            do {
                for user in users {
                    try delete(user: user)
                }

                send(.getServers)
            } catch {
                eventSubject.send(.error(.init(error.localizedDescription)))
            }
        case .getServers:
            do {
                servers = try getServers()
                    .zipped(map: getUsers)
                    .reduce(into: OrderedDictionary<ServerState, [UserState]>()) { partialResult, pair in
                        partialResult[pair.0] = pair.1
                    }

                return .content
            } catch {
                eventSubject.send(.error(.init(error.localizedDescription)))
            }
        case let .signIn(user):

            Task {
                guard let userServer = servers.keys.first(where: { $0.id == user.serverID }) else {
                    assertionFailure("?")
                    return
                }

                let userData = try await user.getUserData(server: userServer)

                StoredValues[.User.data(id: user.id)] = userData
            }

            Defaults[.lastSignedInUserID] = user.id
            Container.userSession.reset()
            Notifications[.didSignIn].post()
        }

        return .content
    }

    private func getServers() throws -> [ServerState] {
        try SwiftfinStore
            .dataStack
            .fetchAll(From<ServerModel>())
            .map(\.state)
            .sorted(using: \.name)
    }

    private func getUsers(for server: ServerState) throws -> [UserState] {
        guard let storedServer = try? dataStack.fetchOne(From<ServerModel>().where(\.$id == server.id)) else {
            throw JellyfinAPIError("Unable to find server for users")
        }

        return storedServer.users
            .map(\.state)
    }

    #warning("TODO: delete corresponding any data/user defaults suite")
    private func delete(user: UserState) throws {
        try dataStack.perform { transaction in
            guard let storedUser = try transaction.fetchOne(From<UserModel>().where(\.$id == user.id)) else {
                throw JellyfinAPIError("Unable to find server to delete")
            }

            let userData = try transaction.fetchAll(
                From<AnyStoredData>()
                    .where(\.$ownerID == user.id)
            )

            transaction.delete(userData)
            UserDefaults.userSuite(id: storedUser.id).removeAll()
            transaction.delete(storedUser)
        }
    }
}
