//
//  Color+tappableClear.swift
//  WalletBase
//
//  Created by Mark Jerde on 3/13/23.
//

import SwiftUI

extension Color {
	static var tappableClear: Self {
		// Minimum non-hidden opacity because hidden and clear items are not tappable in SwiftUI, or at least not as tappable.
		Color.white.opacity(0.02)
	}
}
