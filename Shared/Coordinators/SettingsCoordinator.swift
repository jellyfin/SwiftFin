//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import PulseUI
import Stinsen
import SwiftUI

final class SettingsCoordinator: NavigationCoordinatable {
    let stack = NavigationStack(initial: \SettingsCoordinator.start)

    @Root
    var start = makeStart

    #if os(iOS)
    @Route(.push)
    var log = makeLog
    @Route(.push)
    var nativePlayerSettings = makeNativePlayerSettings
    @Route(.push)
    var playbackQualitySettings = makePlaybackQualitySettings
    @Route(.push)
    var quickConnect = makeQuickConnectAuthorize
    @Route(.push)
    var resetUserPassword = makeResetUserPassword
    @Route(.push)
    var localSecurity = makeLocalSecurity
    @Route(.modal)
    var photoPicker = makePhotoPicker
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
    var serverConnection = makeServerConnection
    @Route(.push)
    var videoPlayerSettings = makeVideoPlayerSettings
    @Route(.push)
    var customDeviceProfileSettings = makeCustomDeviceProfileSettings

    @Route(.push)
    var userDashboard = makeUserDashboard
    @Route(.push)
    var activeSessions = makeActiveSessions
    @Route(.push)
    var activeDeviceDetails = makeActiveDeviceDetails
    @Route(.modal)
    var itemOverviewView = makeItemOverviewView
    @Route(.push)
    var tasks = makeTasks
    @Route(.push)
    var users = makeUsers
    @Route(.push)
    var userDetails = makeUserDetails
    @Route(.push)
    var userDevices = makeUserDevices
    @Route(.push)
    var userPassword = makeUserPassword
    @Route(.push)
    var devices = makeDevices
    @Route(.push)
    var deviceDetails = makeDeviceDetails
    @Route(.push)
    var editScheduledTask = makeEditScheduledTask
    @Route(.push)
    var serverLogs = makeServerLogs

    @Route(.modal)
    var editCustomDeviceProfile = makeEditCustomDeviceProfile
    @Route(.modal)
    var createCustomDeviceProfile = makeCreateCustomDeviceProfile

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
    var log = makeLog
    @Route(.modal)
    var serverDetail = makeServerDetail
    @Route(.modal)
    var videoPlayerSettings = makeVideoPlayerSettings
    @Route(.modal)
    var playbackQualitySettings = makePlaybackQualitySettings
    #endif

    #if os(iOS)
    @ViewBuilder
    func makeNativePlayerSettings() -> some View {
        NativeVideoPlayerSettingsView()
    }

    @ViewBuilder
    func makePlaybackQualitySettings() -> some View {
        PlaybackQualitySettingsView()
    }

    @ViewBuilder
    func makeCustomDeviceProfileSettings() -> some View {
        CustomDeviceProfileSettingsView()
    }

    func makeEditCustomDeviceProfile(profile: Binding<CustomDeviceProfile>)
    -> NavigationViewCoordinator<EditCustomDeviceProfileCoordinator> {
        NavigationViewCoordinator(EditCustomDeviceProfileCoordinator(profile: profile))
    }

    func makeCreateCustomDeviceProfile() -> NavigationViewCoordinator<EditCustomDeviceProfileCoordinator> {
        NavigationViewCoordinator(EditCustomDeviceProfileCoordinator())
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
    func makeLocalSecurity() -> some View {
        UserLocalSecurityView()
    }

    func makePhotoPicker(viewModel: SettingsViewModel) -> NavigationViewCoordinator<UserProfileImageCoordinator> {
        NavigationViewCoordinator(UserProfileImageCoordinator())
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
    func makeServerConnection(server: ServerState) -> some View {
        EditServerView(server: server)
    }

    @ViewBuilder
    func makeUserDashboard() -> some View {
        UserDashboardView()
    }

    @ViewBuilder
    func makeActiveSessions() -> some View {
        ActiveSessionsView()
    }

    @ViewBuilder
    func makeActiveDeviceDetails(box: BindingBox<SessionInfo?>) -> some View {
        ActiveSessionDetailView(box: box)
    }

    func makeItemOverviewView(item: BaseItemDto) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            ItemOverviewView(item: item)
        }
    }

    @ViewBuilder
    func makeTasks() -> some View {
        ScheduledTasksView()
    }

    @ViewBuilder
    func makeUsers() -> some View {
        UserAdministrationView()
    }

    @ViewBuilder
    func makeUserDetails(observer: UserAdministrationObserver) -> some View {
        UserAdministrationDetailView(observer: observer)
    }

    @ViewBuilder
    func makeUserDevices(userId: String) -> some View {
        DevicesView(userId: userId)
    }

    @ViewBuilder
    func makeUserPassword(observer: UserAdministrationObserver) -> some View {
        UserAdmininstrationPasswordView(observer: observer)

    @ViewBuilder
    func makeDevices() -> some View {
        DevicesView()
    }

    @ViewBuilder
    func makeDeviceDetails(device: DeviceInfo) -> some View {
        DeviceDetailsView(device: device)
    }

    @ViewBuilder
    func makeEditScheduledTask(observer: ServerTaskObserver) -> some View {
        EditScheduledTaskView(observer: observer)
    }

    @ViewBuilder
    func makeServerLogs() -> some View {
        ServerLogsView()
    }

    func makeItemFilterDrawerSelector(selection: Binding<[ItemFilterType]>) -> some View {
        OrderedSectionSelectorView(selection: selection, sources: ItemFilterType.allCases)
            .navigationTitle(L10n.filters)
    }

    func makeVideoPlayerSettings() -> VideoPlayerSettingsCoordinator {
        VideoPlayerSettingsCoordinator()
    }

    #if DEBUG
    @ViewBuilder
    func makeDebugSettings() -> some View {
        DebugSettingsView()
    }
    #endif

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
        NavigationViewCoordinator {
            IndicatorSettingsView()
        }
    }

    func makeServerDetail(server: ServerState) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            EditServerView(server: server)
        }
    }

    func makeVideoPlayerSettings() -> NavigationViewCoordinator<VideoPlayerSettingsCoordinator> {
        NavigationViewCoordinator(
            VideoPlayerSettingsCoordinator()
        )
    }

    func makePlaybackQualitySettings() -> NavigationViewCoordinator<PlaybackQualitySettingsCoordinator> {
        NavigationViewCoordinator(
            PlaybackQualitySettingsCoordinator()
        )
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
