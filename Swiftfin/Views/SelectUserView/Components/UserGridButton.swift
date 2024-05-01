//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension SelectUserView {

    struct UserGridButton: View {

        @Environment(\.isEditing)
        private var isEditing
        @Environment(\.isSelected)
        private var isSelected

        private let user: UserState
        private let client: JellyfinClient
        private let action: () -> Void

        init(
            user: UserState,
            client: JellyfinClient,
            action: @escaping () -> Void
        ) {
            self.user = user
            self.client = client
            self.action = action
        }

        private var personView: some View {
            SystemImageContentView(systemName: "person.fill", ratio: 0.5)
        }

        private var labelForegroundStyle: some ShapeStyle {
            guard isEditing else { return .primary }

            return isSelected ? .primary : .secondary
        }

        var body: some View {
            VStack(alignment: .center) {
                Button {
                    action()
                } label: {
                    ZStack {
                        Color.clear

                        ImageView(user.profileImageSource(client: client, maxWidth: 120, maxHeight: 120))
                            .placeholder { _ in
                                personView
                            }
                            .failure {
                                personView
                            }
                    }
                    .aspectRatio(1, contentMode: .fill)
                    .posterShadow()
                    .posterBorder(ratio: 1 / 2, of: \.width)
                    .clipShape(.circle)
                    .overlay {
                        if isEditing {
                            ZStack(alignment: .bottomTrailing) {
                                Color.black
                                    .opacity(isSelected ? 0 : 0.5)

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40, alignment: .bottomTrailing)
                                        .paletteOverlayRendering()
                                }
                            }
                        }
                    }
                }

                Text(user.username)
                    .fontWeight(.semibold)
                    .foregroundStyle(labelForegroundStyle)
                    .lineLimit(1)
            }
        }
    }
}
