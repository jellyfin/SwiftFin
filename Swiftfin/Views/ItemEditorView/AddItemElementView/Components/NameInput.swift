//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension AddItemComponentView {

    struct NameInput: View {

        @Binding
        var name: String
        var type: ItemArrayElements

        @Binding
        var personKind: PersonKind
        @Binding
        var personRole: String

        let matches: [Element]

        // MARK: - Body

        var body: some View {
            nameView

            if type == .people {
                personView
            }
        }

        // MARK: - Name Input Field

        private var nameView: some View {
            Section {
                TextField(L10n.name, text: $name)
                    .autocorrectionDisabled()
            } header: {
                Text(L10n.name)
            } footer: {
                if name.isEmpty || name == "" {
                    Label(
                        L10n.required,
                        systemImage: "exclamationmark.circle.fill"
                    )
                    .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                } else {
                    if type.validateElement(name: name, list: matches) {
                        Label(
                            L10n.existsOnServer,
                            systemImage: "checkmark.circle.fill"
                        )
                        .labelStyle(.sectionFooterWithImage(imageStyle: .green))
                    } else {
                        Label(
                            L10n.willBeCreatedOnServer,
                            systemImage: "checkmark.seal.fill"
                        )
                        .labelStyle(.sectionFooterWithImage(imageStyle: .blue))
                    }
                }
            }
        }

        // MARK: - Person Input Fields

        var personView: some View {
            Section {
                Picker(L10n.type, selection: $personKind) {
                    ForEach(PersonKind.allCases, id: \.self) { kind in
                        Text(kind.displayTitle).tag(kind)
                    }
                }
                if personKind == PersonKind.actor {
                    TextField(L10n.role, text: $personRole)
                        .autocorrectionDisabled()
                }
            }
        }
    }
}
