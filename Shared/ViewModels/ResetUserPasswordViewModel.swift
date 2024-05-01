//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

final class ResetUserPasswordViewModel: ViewModel, Eventful, Stateful {

    // MARK: Event

    enum Event {
        case error(JellyfinAPIError)
        case success
    }

    // MARK: Action

    enum Action: Equatable {
        case reset(current: String, new: String)
    }

    // MARK: State

    enum State: Hashable {
        case initial
        case resetting
    }

    @Published
    var state: State = .initial

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var resetTask: AnyCancellable?
    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    func respond(to action: Action) -> State {
        switch action {
        case let .reset(current, new):
            resetTask = Task {
                do {
                    try await reset(current: current, new: new)

                    await MainActor.run {
                        self.eventSubject.send(.success)
                        self.state = .initial
                    }
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                        self.state = .initial
                    }
                }
            }
            .asAnyCancellable()

            return .resetting
        }
    }

    private func reset(current: String, new: String) async throws {
        let body = UpdateUserPassword(currentPw: current, newPw: new)
        let request = Paths.updateUserPassword(userID: userSession.user.id, body)

        try await userSession.client.send(request)
    }
}
