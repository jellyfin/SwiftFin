//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI
import VLCUI

struct VideoPlayer: View {

    enum OverlayType {
        case chapters
        case confirmClose
        case main
        case smallMenu
    }

    @Environment(\.scenePhase)
    private var scenePhase

    @EnvironmentObject
    private var router: VideoPlayerCoordinator.Router

    @ObservedObject
    private var currentProgressHandler: VideoPlayerManager.CurrentProgressHandler
    @ObservedObject
    private var videoPlayerManager: VideoPlayerManager

    @State
    private var isPresentingOverlay: Bool = false
    @State
    private var isScrubbing: Bool = false

    @ViewBuilder
    private var playerView: some View {
        ZStack {
            VLCVideoPlayer(configuration: videoPlayerManager.currentViewModel.vlcVideoPlayerConfiguration)
                .proxy(videoPlayerManager.proxy)
                .onTicksUpdated { ticks, _ in

                    let newSeconds = ticks / 1000
                    let newProgress = CGFloat(newSeconds) / CGFloat(videoPlayerManager.currentViewModel.item.runTimeSeconds)
                    currentProgressHandler.progress = newProgress
                    currentProgressHandler.seconds = newSeconds

                    guard !isScrubbing else { return }
                    currentProgressHandler.scrubbedProgress = newProgress
                }
                .onStateUpdated { state, _ in

                    videoPlayerManager.onStateUpdated(newState: state)

                    if state == .ended {
                        if let _ = videoPlayerManager.nextViewModel,
                           Defaults[.VideoPlayer.autoPlayEnabled]
                        {
                            videoPlayerManager.selectNextViewModel()
                        } else {
                            router.dismissCoordinator()
                        }
                    }
                }

            VideoPlayer.Overlay()
                .eraseToAnyView()
                .environmentObject(videoPlayerManager)
                .environmentObject(videoPlayerManager.currentProgressHandler)
                .environmentObject(videoPlayerManager.currentViewModel!)
                .environmentObject(videoPlayerManager.proxy)
                .environment(\.isPresentingOverlay, $isPresentingOverlay)
                .environment(\.isScrubbing, $isScrubbing)
                .onPlayPauseCommand(perform: {
                    if videoPlayerManager.state == .playing {
                        videoPlayerManager.proxy.pause()
                        withAnimation(.linear(duration: 0.3)) {
                            isPresentingOverlay = true
                        }
                    } else if videoPlayerManager.state == .paused {
                        videoPlayerManager.proxy.play()
                        withAnimation(.linear(duration: 0.3)) {
                            isPresentingOverlay = false
                        }
                    }
                })
        }
        .onChange(of: videoPlayerManager.currentProgressHandler.scrubbedProgress) { newValue in
            guard !newValue.isNaN && !newValue.isInfinite else {
                return
            }
            DispatchQueue.main.async {
                videoPlayerManager.currentProgressHandler
                    .scrubbedSeconds = Int(CGFloat(videoPlayerManager.currentViewModel.item.runTimeSeconds) * newValue)
            }
        }
        .onDisappear(perform: {
            videoPlayerManager.proxy.stop()
            router.dismissCoordinator()
        })
    }

    @ViewBuilder
    private var loadingView: some View {
        Text("Retrieving media information")
    }

    var body: some View {
        ZStack {

            Color.black

            if let _ = videoPlayerManager.currentViewModel {
                playerView
            } else {
                loadingView
            }
        }
        .ignoresSafeArea()
        .onChange(of: isScrubbing) { newValue in
            guard !newValue else { return }
            videoPlayerManager.proxy.setTime(.seconds(currentProgressHandler.scrubbedSeconds))
        }
        .onScenePhase(.active) {
            if Defaults[.VideoPlayer.Transition.playOnActive] {
                videoPlayerManager.proxy.play()
            }
        }
        .onScenePhase(.background) {
            if Defaults[.VideoPlayer.Transition.pauseOnBackground] {
                videoPlayerManager.proxy.pause()
            }
        }
    }
}

extension VideoPlayer {

    init(manager: VideoPlayerManager) {
        self.init(
            currentProgressHandler: manager.currentProgressHandler,
            videoPlayerManager: manager
        )
    }
}
