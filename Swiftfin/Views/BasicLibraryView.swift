//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CollectionView
import Defaults
import JellyfinAPI
import SwiftUI

struct BasicLibraryView: View {

    @EnvironmentObject
    private var router: BasicLibraryCoordinator.Router
    @ObservedObject
    var viewModel: PagingLibraryViewModel
    
    @Default(.Customization.Library.viewType)
    private var libraryViewType

    @ViewBuilder
    private var loadingView: some View {
        ProgressView()
    }

    @ViewBuilder
    private var noResultsView: some View {
        L10n.noResults.text
    }

    @ViewBuilder
    private var libraryItemsView: some View {
        PagingLibraryView(viewModel: viewModel)
            .onSelect { item in
                router.route(to: \.item, item)
            }
            .ignoresSafeArea()
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                loadingView
            } else if viewModel.items.isEmpty {
                noResultsView
            } else {
                libraryItemsView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {

                if viewModel.isLoading && !viewModel.items.isEmpty {
                    ProgressView()
                }

                Button {
                    switch libraryViewType {
                    case .grid:
                        libraryViewType = .list
                    case .list:
                        libraryViewType = .grid
                    }
                } label: {
                    switch libraryViewType {
                    case .grid:
                        Image(systemName: "list.dash")
                    case .list:
                        Image(systemName: "square.grid.2x2")
                    }
                }
            }
        }
    }
}
