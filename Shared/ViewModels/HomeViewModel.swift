//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Factory
import JellyfinAPI
import OrderedCollections

final class HomeViewModel: ViewModel {

    @Published
    var errorMessage: String?
    @Published
    var libraries: [BaseItemDto] = []
    @Published
    var resumeItems: OrderedSet<BaseItemDto> = []

    var nextUpViewModel: NextUpLibraryViewModel = .init()
    var recentlyAddedViewModel: RecentlyAddedLibraryViewModel = .init()

    override init() {
        super.init()

        refresh()
    }

    @objc
    func refresh() {

        libraries = []
        resumeItems = []

        Task {
            logger.debug("Refreshing home screen")

            await MainActor.run {
                isLoading = true
            }

            refreshResumeItems()
            nextUpViewModel.refresh()
            recentlyAddedViewModel.refresh()

            do {
                try await refreshLibrariesLatest()
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }

                return
            }

            await MainActor.run {
                isLoading = false
                errorMessage = nil
            }
        }
    }

    // MARK: Libraries Latest Items

    private func refreshLibrariesLatest() async throws {
        let userViewsPath = Paths.getUserViews(userID: userSession.user.id)
        let response = try await userSession.client.send(userViewsPath)

        guard let allLibraries = response.value.items else {
            await MainActor.run {
                libraries = []
            }

            return
        }

        let excludedLibraryIDs = await getExcludedLibraries()

        let newLibraries = allLibraries
            .filter { $0.collectionType == "movies" || $0.collectionType == "tvshows" }
            .filter { library in
                !excludedLibraryIDs.contains(where: { $0 == library.id ?? "" })
            }

        await MainActor.run {
            libraries = newLibraries
        }
    }

    private func getExcludedLibraries() async -> [String] {
        let currentUserPath = Paths.getCurrentUser
        let response = try? await userSession.client.send(currentUserPath)

        return response?.value.configuration?.latestItemsExcludes ?? []
    }

    // MARK: Resume Items

    private func refreshResumeItems() {
        Task {
            let resumeParameters = Paths.GetResumeItemsParameters(
                limit: 20,
                fields: ItemFields.minimumCases,
                enableUserData: true,
                includeItemTypes: [.movie, .episode]
            )

            let request = Paths.getResumeItems(userID: userSession.user.id, parameters: resumeParameters)
            let response = try await userSession.client.send(request)

            guard let items = response.value.items else { return }

            await MainActor.run {
                resumeItems = OrderedSet(items)
            }
        }
    }

    func markItemUnplayed(_ item: BaseItemDto) {
        guard resumeItems.contains(where: { $0.id == item.id! }) else { return }

        Task {
            let request = Paths.markUnplayedItem(
                userID: userSession.user.id,
                itemID: item.id!
            )
            let _ = try await userSession.client.send(request)

            refreshResumeItems()
            nextUpViewModel.refresh()
            recentlyAddedViewModel.refresh()
        }
    }

    func markItemPlayed(_ item: BaseItemDto) {
        guard resumeItems.contains(where: { $0.id == item.id! }) else { return }

        Task {
            let request = Paths.markPlayedItem(
                userID: userSession.user.id,
                itemID: item.id!
            )
            let _ = try await userSession.client.send(request)

            refreshResumeItems()
            nextUpViewModel.refresh()
            recentlyAddedViewModel.refresh()
        }
    }
}
