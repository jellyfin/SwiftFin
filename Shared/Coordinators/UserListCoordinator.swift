//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import Stinsen
import SwiftUI

final class UserListCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \UserListCoordinator.start)

    @Root
    var start = makeStart

    @Route(.modal)
    var advancedSettings = makeAdvancedSettings
    @Route(.modal)
    var connectToServer = makeConnectToServer
    @Route(.modal)
    var editServer = makeEditServer
    @Route(.modal)
    var userSignIn = makeUserSignIn

    func makeAdvancedSettings() -> NavigationViewCoordinator<BasicAppSettingsCoordinator> {
        NavigationViewCoordinator(BasicAppSettingsCoordinator())
    }

    func makeConnectToServer() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            ConnectToServerView()
        }
    }

    func makeEditServer(server: ServerState) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            EditServerView(server: server)
                .environment(\.isEditing, true)
        }
    }

    func makeUserSignIn(server: ServerState) -> NavigationViewCoordinator<UserSignInCoordinator> {
        NavigationViewCoordinator(UserSignInCoordinator(server: server))
    }

    @ViewBuilder
    func makeStart() -> some View {
        SelectUserView()
            .preferredColorScheme(.dark)
    }
}
