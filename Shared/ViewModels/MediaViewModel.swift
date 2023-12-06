//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import JellyfinAPI
import OrderedCollections

final class MediaViewModel: ViewModel {

    private static let supportedCollectionTypes: [String] = ["boxsets", "folders", "movies", "tvshows", "unknown"]

    @Published
    var libraries: OrderedSet<MediaItemViewModel> = []

    override init() {
        super.init()

        Task {
            await refresh()
        }
    }

    func refresh() async {
        do {
            let newLibraries = try await getUserLibraries()

            await MainActor.run {
                libraries.elements = newLibraries.map(MediaItemViewModel.init)
                    .prepending(
                        .init(item: .init(collectionType: "liveTV", name: L10n.liveTV)),
                        if: Defaults[.Experimental.liveTVAlphaEnabled]
                    )
                    .prepending(
                        .init(item: .init(collectionType: "favorites", name: L10n.favorites)),
                        if: Defaults[.Customization.Library.showFavorites]
                    )
                    .prepending(
                        .init(item: .init(collectionType: "downloads", name: L10n.downloads)),
                        if: Defaults[.Experimental.downloads]
                    )
            }
        } catch {
            // TODO: set error once MediaView has error + retry state
            await MainActor.run {
                libraries = []
            }
        }
    }

    private func getUserLibraries() async throws -> [BaseItemDto] {
        let request = Paths.getUserViews(userID: userSession.user.id)
        let response = try await userSession.client.send(request)

        guard let items = response.value.items else { return [] }
        let supportedLibraries = items.filter(using: \.collectionType, by: Self.supportedCollectionTypes)

        return supportedLibraries
    }
}
