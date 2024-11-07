//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension ItemView {

    struct ActionMenu<Content: View>: View {

        @Environment(\.isSelected)
        private var isSelected
        @FocusState
        private var isFocused: Bool

        @ViewBuilder
        let menuItems: Content

        @State
        private var isShowingMenu = false

        // MARK: - Body

        var body: some View {
            Menu {
                menuItems
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isFocused ? Color.white : Color.white.opacity(0.5))
                        .frame(width: 70, height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? Color.black : Color.clear, lineWidth: 2)
                        )

                    Label(L10n.menuButtons, systemImage: "ellipsis")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                        .labelStyle(.iconOnly)
                }
            }
            .focused($isFocused)
            .scaleEffect(isFocused ? 1.20 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .frame(width: 70, height: 100)
            .buttonStyle(.borderless)
        }
    }
}
