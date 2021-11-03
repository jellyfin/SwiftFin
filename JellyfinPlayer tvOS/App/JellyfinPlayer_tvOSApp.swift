//
// SwiftFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2021 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

@main
struct JellyfinPlayer_tvOSApp: App {

	var body: some Scene {
		WindowGroup {
			MainCoordinator().view()
		}
	}
}
