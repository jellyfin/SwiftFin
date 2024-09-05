//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

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

class ActiveSessionsViewModel: ViewModel {
    @Published
    var sessions: [SessionInfo] = []
    @Published
    var isLoading = false
    @Published
    var error: Error?

    func loadSessions() {
        isLoading = true
        error = nil

        Task {
            do {
                let fetchedSessions = try await get()
                DispatchQueue.main.async {
                    self.sessions = fetchedSessions
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                }
            }
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }

    private func get() async throws -> [SessionInfo] {
        let parameters = parameters()
        let request = Paths.getSessions(parameters: parameters)
        let response = try await userSession.client.send(request)
        return response.value
    }

    private func parameters() -> Paths.GetSessionsParameters {
        var parameters = Paths.GetSessionsParameters()
        parameters.activeWithinSeconds = 960
        return parameters
    }
}
