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

final class LiveTVTabCoordinator: TabCoordinatable {

    var child = TabChild(startingItems: [
        \LiveTVTabCoordinator.programs,
        \LiveTVTabCoordinator.channels,
    ])

    @Route(tabItem: makeProgramsTab)
    var programs = makePrograms
    @Route(tabItem: makeChannelsTab)
    var channels = makeChannels

    func makePrograms() -> NavigationViewCoordinator<LiveTVProgramsCoordinator> {
        NavigationViewCoordinator(LiveTVProgramsCoordinator())
    }

    @ViewBuilder
    func makeProgramsTab(isActive: Bool) -> some View {
        Label(L10n.programs, systemImage: "tv")
    }

    func makeChannels() -> NavigationViewCoordinator<LiveTVChannelsCoordinator> {
        NavigationViewCoordinator(LiveTVChannelsCoordinator())
    }

    @ViewBuilder
    func makeChannelsTab(isActive: Bool) -> some View {
        Label(L10n.channels, systemImage: "play.square.stack")
    }
}
