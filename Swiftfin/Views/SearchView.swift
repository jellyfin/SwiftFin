//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionView
import Defaults
import JellyfinAPI
import SwiftUI

struct SearchView: View {

    @Default(.Customization.searchPosterType)
    private var searchPosterType

    @EnvironmentObject
    private var router: SearchCoordinator.Router

    @ObservedObject
    var viewModel: SearchViewModel

    @State
    private var searchQuery = ""

    @ViewBuilder
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.search(query: searchQuery))
            }
    }

    @ViewBuilder
    private var suggestionsView: some View {
        VStack(spacing: 20) {
            Spacer()

            ForEach(viewModel.suggestions) { item in
                Button {
                    searchQuery = item.displayTitle
                } label: {
                    Text(item.displayTitle)
                        .font(.body)
                }
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var resultsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if viewModel.movies.isNotEmpty {
                    itemsSection(title: L10n.movies, keyPath: \.movies, posterType: searchPosterType)
                }

                if viewModel.collections.isNotEmpty {
                    itemsSection(title: L10n.collections, keyPath: \.collections, posterType: searchPosterType)
                }

                if viewModel.series.isNotEmpty {
                    itemsSection(title: L10n.tvShows, keyPath: \.series, posterType: searchPosterType)
                }

                if viewModel.episodes.isNotEmpty {
                    itemsSection(title: L10n.episodes, keyPath: \.episodes, posterType: searchPosterType)
                }

                if viewModel.people.isNotEmpty {
                    itemsSection(title: L10n.people, keyPath: \.people, posterType: .portrait)
                }
            }
        }
    }

    private func baseItemOnSelect(_ item: BaseItemDto) {
        if item.type == .person {
            let viewModel = PagingLibraryViewModel<BaseItemDto>(parent: item)
            router.route(to: \.library, viewModel)
        } else {
            router.route(to: \.item, item)
        }
    }

    @ViewBuilder
    private func itemsSection(
        title: String,
        keyPath: ReferenceWritableKeyPath<SearchViewModel, [BaseItemDto]>,
        posterType: PosterType
    ) -> some View {
        PosterHStack(
            title: title,
            type: posterType,
            items: viewModel[keyPath: keyPath]
        )
        .onSelect { item in
            baseItemOnSelect(item)
        }
    }

    var body: some View {
        WrappedView {
            Group {
                switch viewModel.state {
                case let .error(error):
                    errorView(with: error)
                case .initial:
                    suggestionsView
                case .items:
                    if viewModel.hasNoResults {
                        L10n.noResults.text
                    } else {
                        resultsView
                    }
                case .searching:
                    ProgressView()
                }
            }
            .transition(.opacity.animation(.linear(duration: 0.1)))
        }
        .onFirstAppear {
            viewModel.send(.getSuggestions)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationTitle(L10n.search)
        .navigationBarTitleDisplayMode(.inline)
        .navBarDrawer {
            ScrollView(.horizontal, showsIndicators: false) {
                FilterDrawerHStack(viewModel: viewModel.filterViewModel, types: ItemFilterType.allCases)
                    .onSelect {
                        router.route(to: \.filter, $0)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 1)
            }
        }
        .onChange(of: searchQuery) { newValue in
            viewModel.send(.search(query: newValue))
        }
        .searchable(
            text: $searchQuery,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: L10n.search
        )
    }
}
