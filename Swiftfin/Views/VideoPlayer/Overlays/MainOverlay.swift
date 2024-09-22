//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer {

    struct MainOverlay: View {

        @Default(.VideoPlayer.Overlay.playbackButtonType)
        private var playbackButtonType

        @Environment(\.isPresentingOverlay)
        @Binding
        private var isPresentingOverlay
        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool
        @Environment(\.safeAreaInsets)
        @Binding
        private var safeAreaInsets

        @State
        private var effectiveSafeArea: EdgeInsets = .zero

        @StateObject
        private var overlayTimer: DelayIntervalTimer = .init(defaultInterval: 5)

        @ViewBuilder
        private var topBar: some View {
            Overlay.TopBarView()
                .edgePadding(.vertical)
                .padding(effectiveSafeArea)
                .background {
                    OpacityLinearGradient {
                        (0, 0.9)
                        (1, 0)
                    }
                    .foregroundStyle(.black)
                    .visible(playbackButtonType == .compact)
                }
                .visible(!isScrubbing && isPresentingOverlay)
                .offset(y: isPresentingOverlay ? 0 : -20)
                .animation(.bouncy, value: isPresentingOverlay)
        }

        @ViewBuilder
        private var bottomBar: some View {
            Overlay.BottomBarView()
                .edgePadding(.vertical)
                .padding(effectiveSafeArea)
                .background {
                    OpacityLinearGradient {
                        (0, 0)
                        (1, 0.9)
                    }
                    .foregroundStyle(.black)
                    .visible(isScrubbing || playbackButtonType == .compact)
                }
                .visible(isScrubbing || isPresentingOverlay)
                .transition(.move(edge: .top).combined(with: .opacity))
                .offset(y: isPresentingOverlay ? 0 : 20)
                .animation(.bouncy, value: isPresentingOverlay)
        }

        var body: some View {
            ZStack {

                Color.black
                    .opacity(!isScrubbing && playbackButtonType == .large && isPresentingOverlay ? 0.5 : 0)
                    .allowsHitTesting(false)

                VStack {
                    topBar

                    Spacer()
                        .allowsHitTesting(false)

                    bottomBar

//                    DrawerSectionView(selectedDrawerSection: $selectedDrawerIndex)
//                        .offset(y: isPresentingOverlay ? 0 : 10)
//                        .animation(.bouncy, value: isPresentingOverlay)
//                        .visible(!isScrubbing)
//
//                    if isPresentingDrawer {
//                        Color.red
//                            .frame(height: 100)
//                            .transition(.move(edge: .bottom).combined(with: .opacity))
//                    }
                }

                if playbackButtonType == .large {
                    Overlay.LargePlaybackButtons()
                        .visible(!isScrubbing && isPresentingOverlay)
                }
            }
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .environmentObject(overlayTimer)
//            .onChange(of: isPresentingDrawer) { newValue in
//                print("here")
//                if newValue {
//                    overlayTimer.stop()
//                } else {
//                    overlayTimer.delay()
//                }
//            }
            .onChange(of: isPresentingOverlay) { newValue in
                guard newValue, !isScrubbing else { return }
                overlayTimer.delay()
            }
            .onChange(of: isScrubbing) { newValue in
                if newValue {
                    overlayTimer.stop()
                } else {
                    overlayTimer.delay()
                }
            }
            .onReceive(overlayTimer.hasFired) { _ in
                guard !isScrubbing else { return }

                withAnimation(.linear(duration: 0.3)) {
                    isPresentingOverlay = false
                }
            }
            .onSizeChanged { newSize in
                if newSize.isPortrait {
                    effectiveSafeArea = .init(
                        vertical: min(safeAreaInsets.top, safeAreaInsets.bottom),
                        horizontal: 0
                    )
                } else {
                    effectiveSafeArea = .init(
                        vertical: 0,
                        horizontal: min(safeAreaInsets.leading, safeAreaInsets.trailing)
                    )
                }
            }
        }
    }
}
