//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

extension CustomizeViewsSettings {

    struct ItemSection: View {

        @Injected(\.currentUserSession)
        private var userSession

        @StoredValue(.User.enableCriticRatings)
        private var enableCriticRatings
        @StoredValue(.User.enableCommunityRatings)
        private var enableCommunityRatings

        @StoredValue(.User.enableItemEditing)
        private var enableItemEditing
        @StoredValue(.User.enableItemDeletion)
        private var enableItemDeletion
        @StoredValue(.User.enableCollectionManagement)
        private var enableCollectionManagement

        var body: some View {
            Section(L10n.items) {

                Toggle(L10n.criticRatings, isOn: $enableCriticRatings)

                Toggle(L10n.communityRatings, isOn: $enableCommunityRatings)
            }

            if userSession?.user.permissions.items.canEditMetadata ?? false
                || userSession?.user.permissions.items.canDelete ?? false
                // || userSession?.user.permissions.items.canDownload ?? false
                || userSession?.user.permissions.items.canManageCollections ?? false
            // || userSession?.user.permissions.items.canManageLyrics ?? false
            // || userSession?.user.permissions.items.canManageSubtitles
            {
                Section(L10n.management) {
                    /// Enable Editing Items from All Visible LIbraries
                    if userSession?.user.permissions.items.canEditMetadata ?? false {
                        Toggle(L10n.allowItemEditing, isOn: $enableItemEditing)
                    }
                    /// Enable Deleting Items from Approved Libraries
                    if userSession?.user.permissions.items.canDelete ?? false {
                        Toggle(L10n.allowItemDeletion, isOn: $enableItemDeletion)
                    }
                    /// Enable Downloading All Items
                    /* if userSession?.user.permissions.items.canDownload ?? false {
                     Toggle(L10n.allowItemDownloading, isOn: $enableItemDownloads)
                     } */
                    /// Enable Deleting or Editing Collections
                    if userSession?.user.permissions.items.canManageCollections ?? false {
                        Toggle(L10n.allowCollectionManagement, isOn: $enableCollectionManagement)
                    }
                    /// Manage Item Lyrics
                    /* if userSession?.user.permissions.items.canManageLyrics ?? false {
                     Toggle(L10n.allowLyricsManagement isOn: $enableLyricsManagement)
                     } */
                    /// Manage Item Subtitles
                    /* if userSession?.user.items.canManageSubtitles ?? false {
                     Toggle(L10n.allowSubtitleManagement, isOn: $enableSubtitleManagement)
                     } */
                }
            }
        }
    }
}
