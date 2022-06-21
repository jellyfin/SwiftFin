//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension MovieItemView {
    
    struct ContentView: View {
        
        @EnvironmentObject
        var itemRouter: ItemCoordinator.Router
        @ObservedObject
        var viewModel: MovieItemViewModel
        @Default(.itemViewType)
        private var itemViewType
        
        var body: some View {
            VStack(alignment: .leading) {
                
                if case ItemViewType.compactPoster = itemViewType {
                    if let firstTagline = viewModel.playButtonItem?.taglines?.first {
                        Text(firstTagline)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.bottom)
                            .lineLimit(2)
                    }
                    
                    if let itemOverview = viewModel.item.overview {
                        TruncatedTextView(itemOverview,
                                          lineLimit: 4,
                                          font: UIFont.preferredFont(forTextStyle: .footnote)) {
                            itemRouter.route(to: \.itemOverview, viewModel.item)
                        }
                                          .fixedSize()
                                          .padding(.horizontal)
                                          .padding(.bottom)
                    }
                }
                
                // MARK: Genres

                if let genres = viewModel.item.genreItems, !genres.isEmpty {
                    PillHStackView(title: L10n.genres,
                                   items: genres,
                                   selectedAction: { genre in
                                       itemRouter.route(to: \.library, (viewModel: .init(genre: genre), title: genre.title))
                                   })
                    .padding(.bottom)
                }

                // MARK: Studios

                if let studios = viewModel.item.studios, !studios.isEmpty {
                    PillHStackView(title: L10n.studios,
                                   items: studios) { studio in
                        itemRouter.route(to: \.library, (viewModel: .init(studio: studio), title: studio.name ?? ""))
                    }
                                   .padding(.bottom)
                }

                if let castAndCrew = viewModel.item.people, !castAndCrew.isEmpty {
                    PortraitImageHStackView(items: castAndCrew.filter { BaseItemPerson.DisplayedType.allCasesRaw.contains($0.type ?? "") },
                                            topBarView: {
                                                L10n.castAndCrew.text
                                                    .font(.title3)
                                                    .fontWeight(.semibold)
                                                    .padding(.bottom)
                                                    .padding(.horizontal)
                                                    .accessibility(addTraits: [.isHeader])
                                            },
                                            selectedAction: { person in
                                                itemRouter.route(to: \.library, (viewModel: .init(person: person), title: person.title))
                                            })
                                            .fixedSize(horizontal: false, vertical: true)
                                            .padding(.bottom)
                }

                // MARK: Recommended

                if !viewModel.similarItems.isEmpty {
                    PortraitImageHStackView(items: viewModel.similarItems,
                                            topBarView: {
                                                L10n.recommended.text
                                                    .font(.title3)
                                                    .fontWeight(.semibold)
                                                    .padding(.bottom)
                                                    .padding(.horizontal)
                                                    .accessibility(addTraits: [.isHeader])
                                            },
                                            selectedAction: { item in
                                                itemRouter.route(to: \.item, item)
                                            })
                                            .fixedSize(horizontal: false, vertical: true)
                                            .padding(.bottom)
                }
                
                ZStack {
                    Color.secondarySystemFill
                    
                    VStack(alignment: .leading) {
                        ItemView.AboutView(viewModel: viewModel)

                        // MARK: Details

                        if let informationItems = viewModel.item.createInformationItems(), !informationItems.isEmpty {
                            ListDetailsView(title: L10n.information, items: informationItems)
                                .padding(.horizontal)
                        }

                        if let mediaItems = viewModel.selectedVideoPlayerViewModel?.item.createMediaItems(), !mediaItems.isEmpty {
                            ListDetailsView(title: L10n.media, items: mediaItems)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
}
