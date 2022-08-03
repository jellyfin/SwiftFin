//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import Introspect
import JellyfinAPI
import SwiftUI

struct HomeView: View {

    @EnvironmentObject
    private var router: HomeCoordinator.Router
    @ObservedObject
    var viewModel: HomeViewModel

    var body: some View {
        if viewModel.isLoading {
            ProgressView()
                .scaleEffect(2)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading) {

                    if viewModel.resumeItems.isEmpty {
                        HomeCinematicView(
                            viewModel: viewModel,
                            items: viewModel.latestAddedItems.map { .init(item: $0, type: .plain) },
                            forcedItemSubtitle: L10n.recentlyAdded
                        )
                        
                        if !viewModel.nextUpItems.isEmpty {
                            PortraitPosterHStack(title: L10n.nextUp,
                                                 items: viewModel.nextUpItems) { item in
                                router.route(to: \.item, item)
                            }
                        }
                    } else {
                        HomeCinematicView(
                            viewModel: viewModel,
                            items: viewModel.resumeItems.map { .init(item: $0, type: .resume) }
                        )
                        
                        if !viewModel.nextUpItems.isEmpty {
                            PortraitPosterHStack(title: L10n.nextUp,
                                                 items: viewModel.nextUpItems) { item in
                                router.route(to: \.item, item)
                            }
                        }
                        
                        if !viewModel.latestAddedItems.isEmpty {
                            PortraitPosterHStack(title: L10n.recentlyAdded,
                                                 items: viewModel.latestAddedItems) { item in
                                router.route(to: \.item, item)
                            }
                        }
                    }

                    ForEach(viewModel.libraries, id: \.self) { library in
                        LatestInLibraryView(viewModel: LatestMediaViewModel(library: library))
                    }

//                    Spacer(minLength: 100)

//                    HStack {
//                        Spacer()
//
//
//
//                        Spacer()
//                    }
                }
            }
            .edgesIgnoringSafeArea(.top)
            .edgesIgnoringSafeArea(.horizontal)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.refresh()
                    } label: {
                        L10n.refresh.text
                    }
                }
            }
        }
    }
}
