//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension UserAdministrationDetailView {

    struct UserFunctionButton: View {

        let title: String
        let systemImage: String
        let warningMessage: String
        let isPresented: Binding<Bool>
        let isDestructive: Bool
        let action: () -> Void

        // MARK: - Body

        var body: some View {
            Button(role: isDestructive ? .destructive : .none) {
                isPresented.wrappedValue = true
            } label: {
                Text(title)
            }
            .buttonStyle(.bordered)
            .padding()
            .confirmationDialog(
                title,
                isPresented: isPresented,
                titleVisibility: .hidden
            ) {
                Button(title, role: .destructive, action: action)
            } message: {
                Text(warningMessage)
            }
        }
    }
}
