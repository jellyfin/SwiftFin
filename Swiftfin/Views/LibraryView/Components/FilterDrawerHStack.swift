//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct FilterDrawerHStack: View {

    @ObservedObject
    var viewModel: FilterViewModel
    private var onSelect: (FilterCoordinator.Parameters) -> Void

    var body: some View {
        HStack {
            if viewModel.currentFilters.hasFilters {
                Menu {
                    Button(role: .destructive) {
                        viewModel.currentFilters = .init()
                    } label: {
                        L10n.reset.text
                    }
                } label: {
                    FilterDrawerButton(systemName: "line.3.horizontal.decrease.circle.fill", activated: true)
                }
            }

            FilterDrawerButton(title: "Genres", activated: viewModel.currentFilters.genres != [])
                .onSelect {
                    onSelect(.init(
                        title: "Genres",
                        viewModel: viewModel,
                        filter: \.genres,
                        selectorType: .multi
                    ))
                }

            FilterDrawerButton(title: "Tags", activated: viewModel.currentFilters.tags != [])
                .onSelect {
                    onSelect(.init(
                        title: "Tags",
                        viewModel: viewModel,
                        filter: \.tags,
                        selectorType: .multi
                    ))
                }

            FilterDrawerButton(title: "Filters", activated: viewModel.currentFilters.filters != [])
                .onSelect {
                    onSelect(.init(
                        title: "Filters",
                        viewModel: viewModel,
                        filter: \.filters,
                        selectorType: .multi
                    ))
                }

            FilterDrawerButton(title: "Order", activated: viewModel.currentFilters.sortOrder != [APISortOrder.ascending.filter])
                .onSelect {
                    onSelect(.init(
                        title: "Order",
                        viewModel: viewModel,
                        filter: \.sortOrder,
                        selectorType: .single
                    ))
                }

            FilterDrawerButton(title: "Sort", activated: viewModel.currentFilters.sortBy != [SortBy.name.filter])
                .onSelect {
                    onSelect(.init(
                        title: "Sort",
                        viewModel: viewModel,
                        filter: \.sortBy,
                        selectorType: .single
                    ))
                }
        }
    }
}

extension FilterDrawerHStack {
    init(viewModel: FilterViewModel) {
        self.viewModel = viewModel
        self.onSelect = { _ in }
    }

    func onSelect(_ onSelect: @escaping (FilterCoordinator.Parameters) -> Void) -> Self {
        var copy = self
        copy.onSelect = onSelect
        return copy
    }
}
