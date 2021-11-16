//
//  WalletBaseApp.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/10/21.
//

import SwiftUI

@main
struct WalletBaseApp: App {
	var body: some Scene {
		WindowGroup {
#if os(macOS)
			MainView()
				.frame(minWidth: 976, maxWidth: .infinity, minHeight: 576, maxHeight: .infinity, alignment: .center)
#else
			MainView()
#endif
		}
	}
}
