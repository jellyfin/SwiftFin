//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections

private let DefaultPageSize = 50

class RemoteItemImageViewModel: ViewModel, Stateful, Eventful {

    enum Event: Equatable {
        case updated
        case error(JellyfinAPIError)
    }

    enum Action: Equatable {
        case refresh
        case getNextPage
        case setImage(imageURL: String? = nil, imageData: Data? = nil)
        case deleteImage
    }

    enum BackgroundState: Hashable {
        case gettingNextPage
        case refreshing
        case updating
    }

    enum State: Hashable {
        case initial
        case content
        case error(JellyfinAPIError)
    }

    @Published
    var state: State = .initial
    @Published
    var backgroundStates: OrderedSet<BackgroundState> = []

    @Published
    var item: BaseItemDto
    @Published
    var imageType: ImageType
    @Published
    var imageIndex: Int?
    @Published
    var includeAllLanguages: Bool
    @Published
    var images: OrderedSet<RemoteImageInfo> = []

    private let pageSize: Int
    private(set) var currentPage: Int = 0
    private(set) var hasNextPage: Bool = true

    private var task: AnyCancellable?
    private let eventSubject = PassthroughSubject<Event, Never>()

    var events: AnyPublisher<Event, Never> {
        eventSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    // MARK: - Init

    init(
        item: BaseItemDto,
        imageType: ImageType,
        includeAllLanguages: Bool = false,
        imageIndex: Int? = nil,
        pageSize: Int = DefaultPageSize
    ) {
        self.item = item
        self.imageType = imageType
        self.includeAllLanguages = includeAllLanguages
        self.imageIndex = imageIndex
        self.pageSize = pageSize
        super.init()
    }

    // MARK: - Respond to Actions

    func respond(to action: Action) -> State {
        switch action {
        case .refresh:
            task?.cancel()

            task = Task { [weak self] in
                guard let self else { return }
                do {
                    await MainActor.run {
                        self.state = .initial
                        self.images.removeAll()
                        self.currentPage = 0
                        self.hasNextPage = true
                        _ = self.backgroundStates.append(.refreshing)
                    }

                    try await self.getNextPage()

                    await MainActor.run {
                        self.state = .content
                        self.eventSubject.send(.updated)
                        _ = self.backgroundStates.remove(.refreshing)
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.state = .error(apiError)
                        self.eventSubject.send(.error(apiError))
                        _ = self.backgroundStates.remove(.refreshing)
                    }
                }
            }.asAnyCancellable()

            return state

        case .getNextPage:
            guard hasNextPage else { return .content }
            task?.cancel()
            task = Task { [weak self] in
                guard let self else { return }
                do {
                    await MainActor.run {
                        _ = self.backgroundStates.append(.gettingNextPage)
                    }

                    try await self.getNextPage()

                    await MainActor.run {
                        self.state = .content
                        self.eventSubject.send(.updated)
                        _ = self.backgroundStates.remove(.gettingNextPage)
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.state = .error(apiError)
                        self.eventSubject.send(.error(apiError))
                        _ = self.backgroundStates.remove(.gettingNextPage)
                    }
                }
            }.asAnyCancellable()

            return state

        case let .setImage(imageURL, imageData):
            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        _ = self.backgroundStates.append(.updating)
                    }

                    try await self.setImage(
                        self.imageType,
                        imageURL: imageURL,
                        imageData: imageData,
                        index: self.imageIndex
                    )

                    await MainActor.run {
                        self.eventSubject.send(.updated)
                        _ = self.backgroundStates.remove(.updating)
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.state = .error(apiError)
                        self.eventSubject.send(.error(apiError))
                        _ = self.backgroundStates.remove(.updating)
                    }
                }
            }.asAnyCancellable()

            return state

        case .deleteImage:
            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        _ = self.backgroundStates.append(.updating)
                    }

                    try await self.deleteImage(self.imageType, index: self.imageIndex)

                    await MainActor.run {
                        self.eventSubject.send(.updated)
                        _ = self.backgroundStates.remove(.updating)
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.state = .error(apiError)
                        self.eventSubject.send(.error(apiError))
                        _ = self.backgroundStates.remove(.updating)
                    }
                }
            }.asAnyCancellable()

            return state
        }
    }

    // MARK: - Paging Logic

    private func getNextPage() async throws {
        guard let itemID = item.id, hasNextPage else { return }

        let startIndex = currentPage * pageSize
        let parameters = Paths.GetRemoteImagesParameters(
            type: imageType,
            startIndex: startIndex,
            limit: pageSize,
            isIncludeAllLanguages: includeAllLanguages
        )

        let request = Paths.getRemoteImages(itemID: itemID, parameters: parameters)
        let response = try await userSession.client.send(request)
        let fetchedImages = response.value.images ?? []

        hasNextPage = fetchedImages.count >= pageSize

        await MainActor.run {
            images.append(contentsOf: fetchedImages)
            currentPage += 1
        }
    }

    // MARK: - Set Image

    private func setImage(
        _ type: ImageType,
        imageURL: String? = nil,
        imageData: Data? = nil,
        index: Int? = nil
    ) async throws {

        guard let itemID = item.id else { return }

        var uploadData: Data?

        if let imageData {
            uploadData = imageData
        } else if let imageURL {
            let parameters = Paths.DownloadRemoteImageParameters(type: type, imageURL: imageURL)
            let imageRequest = Paths.downloadRemoteImage(itemID: itemID, parameters: parameters)
            let response = try await userSession.client.send(imageRequest)

            uploadData = response.data
        }

        if let imageData = uploadData {
            if let index {
                let updateRequest = Paths.setItemImageByIndex(
                    itemID: itemID,
                    imageType: type.rawValue,
                    imageIndex: index,
                    imageData
                )
                _ = try await userSession.client.send(updateRequest)
            } else {
                let updateRequest = Paths.setItemImage(
                    itemID: itemID,
                    imageType: type.rawValue,
                    imageData
                )
                _ = try await userSession.client.send(updateRequest)
            }
        } else {
            throw JellyfinAPIError("No image data provided or downloaded.")
        }

        try await refreshItem()
    }

    // MARK: - Delete Image

    private func deleteImage(_ type: ImageType, index: Int?) async throws {
        guard let itemID = item.id else { return }

        if let index {
            let request = Paths.deleteItemImageByIndex(itemID: itemID, imageType: type.rawValue, imageIndex: index)
            _ = try await userSession.client.send(request)
        } else {
            let request = Paths.deleteItemImage(itemID: itemID, imageType: type.rawValue)
            _ = try await userSession.client.send(request)
        }

        try await refreshItem()
    }

    // MARK: - Refresh Item

    private func refreshItem() async throws {
        guard let itemId = item.id else { return }

        await MainActor.run {
            _ = backgroundStates.append(.refreshing)
        }

        let request = Paths.getItem(userID: userSession.user.id, itemID: itemId)
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.item = response.value
            _ = backgroundStates.remove(.refreshing)
            Notifications[.itemMetadataDidChange].post(object: item)
        }
    }
}
