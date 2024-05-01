//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Factory
import SwiftUI

// Note: uses environment `isEditing` for deletion button. This was done
//       to just prevent having 2 views that looked/interacted the same
//       except for a single button.

struct EditServerView: View {

    @EnvironmentObject
    private var router: UserListCoordinator.Router

    @Environment(\.isEditing)
    private var isEditing

    @State
    private var currentServerURL: URL
    @State
    private var isPresentingConfirmDeletion: Bool = false

    @StateObject
    private var viewModel: EditServerViewModel

    init(server: ServerState) {
        self._viewModel = StateObject(wrappedValue: EditServerViewModel(server: server))
        self._currentServerURL = State(initialValue: server.currentURL)
    }

    var body: some View {
        List {
            Section {

                TextPairView(
                    leading: L10n.name,
                    trailing: viewModel.server.name
                )

                Picker(L10n.url, selection: $currentServerURL) {
                    ForEach(viewModel.server.urls.sorted(using: \.absoluteString)) { url in
                        Text(url.absoluteString)
                            .tag(url)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if isEditing {
                Button("Delete", role: .destructive) {
                    isPresentingConfirmDeletion = true
                }
                .buttonStyle(.plain)
                .font(.body.weight(.semibold))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.red.opacity(0.1))
            }
        }
        .navigationTitle(L10n.server)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: currentServerURL) { newValue in
            viewModel.setCurrentURL(to: newValue)
        }
        .alert("Delete Server", isPresented: $isPresentingConfirmDeletion) {
            Button("Delete", role: .destructive) {
                viewModel.delete()
                router.popLast()
            }
        } message: {
            Text("Are you sure you want to delete \(viewModel.server.name) and all of its connected users?")
        }
    }
}
