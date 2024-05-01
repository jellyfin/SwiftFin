//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import PulseUI
import Stinsen
import SwiftUI

final class SettingsCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \SettingsCoordinator.start)

    @Root
    var start = makeStart

    #if os(iOS)
    @Route(.push)
    var about = makeAbout
    @Route(.push)
    var log = makeLog
    @Route(.push)
    var nativePlayerSettings = makeNativePlayerSettings
    @Route(.push)
    var quickConnect = makeQuickConnectAuthorize
    @Route(.push)
    var resetUserPassword = makeResetUserPassword
    @Route(.push)
    var userProfile = makeUserProfileSettings

    @Route(.push)
    var customizeViewsSettings = makeCustomizeViewsSettings
    @Route(.push)
    var experimentalSettings = makeExperimentalSettings
    @Route(.push)
    var itemFilterDrawerSelector = makeItemFilterDrawerSelector
    @Route(.push)
    var indicatorSettings = makeIndicatorSettings
    @Route(.push)
    var serverDetail = makeServerDetail
    @Route(.push)
    var videoPlayerSettings = makeVideoPlayerSettings

    #if DEBUG
    @Route(.push)
    var debugSettings = makeDebugSettings
    #endif
    #endif

    #if os(tvOS)
    @Route(.modal)
    var customizeViewsSettings = makeCustomizeViewsSettings
    @Route(.modal)
    var experimentalSettings = makeExperimentalSettings
    @Route(.modal)
    var indicatorSettings = makeIndicatorSettings
    @Route(.modal)
    var log = makeLog
    @Route(.modal)
    var serverDetail = makeServerDetail
    @Route(.modal)
    var videoPlayerSettings = makeVideoPlayerSettings
    #endif

    #if os(iOS)
    @ViewBuilder
    func makeAbout(viewModel: SettingsViewModel) -> some View {
        AboutAppView(viewModel: viewModel)
    }

    @ViewBuilder
    func makeNativePlayerSettings() -> some View {
        NativeVideoPlayerSettingsView()
    }

    @ViewBuilder
    func makeQuickConnectAuthorize() -> some View {
        QuickConnectAuthorizeView()
    }

    @ViewBuilder
    func makeResetUserPassword() -> some View {
        ResetUserPasswordView()
    }

    @ViewBuilder
    func makeUserProfileSettings(viewModel: SettingsViewModel) -> some View {
        UserProfileSettingsView(viewModel: viewModel)
    }

    @ViewBuilder
    func makeCustomizeViewsSettings() -> some View {
        CustomizeViewsSettings()
    }

    @ViewBuilder
    func makeExperimentalSettings() -> some View {
        ExperimentalSettingsView()
    }

    @ViewBuilder
    func makeIndicatorSettings() -> some View {
        IndicatorSettingsView()
    }

    @ViewBuilder
    func makeServerDetail(server: ServerState) -> some View {
        EditServerView(server: server)
    }

    #if DEBUG
    @ViewBuilder
    func makeDebugSettings() -> some View {
        DebugSettingsView()
    }
    #endif

    func makeItemFilterDrawerSelector(selection: Binding<[ItemFilterType]>) -> some View {
        OrderedSectionSelectorView(selection: selection, sources: ItemFilterType.allCases)
    }

    func makeVideoPlayerSettings() -> VideoPlayerSettingsCoordinator {
        VideoPlayerSettingsCoordinator()
    }

    #endif

    #if os(tvOS)
    func makeCustomizeViewsSettings() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator(
            BasicNavigationViewCoordinator {
                CustomizeViewsSettings()
            }
        )
    }

    func makeExperimentalSettings() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator(
            BasicNavigationViewCoordinator {
                ExperimentalSettingsView()
            }
        )
    }

    func makeIndicatorSettings() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator(
            BasicNavigationViewCoordinator {
                IndicatorSettingsView()
            }
        )
    }

    func makeServerDetail(server: ServerState) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator(
            BasicNavigationViewCoordinator {
                ServerDetailView(server: server)
            }
        )
    }

    func makeVideoPlayerSettings() -> NavigationViewCoordinator<VideoPlayerSettingsCoordinator> {
        NavigationViewCoordinator(VideoPlayerSettingsCoordinator())
    }
    #endif

    @ViewBuilder
    func makeLog() -> some View {
        ConsoleView()
    }

    @ViewBuilder
    func makeStart() -> some View {
        SettingsView()
    }
}
