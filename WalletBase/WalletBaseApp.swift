//
//  WalletBaseApp.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/10/21.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationWillTerminate(_ notification: Notification) {
		// Signal inactivity to lock the wallet.
		ActivityMonitor.shared.onInactivity?()
	}
}

@main
struct WalletBaseApp: App {
#if os(macOS)
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif

	var body: some Scene {
		WindowGroup {
#if os(macOS)
			MainView()
				.frame(minWidth: 976, maxWidth: .infinity, minHeight: 576, maxHeight: .infinity, alignment: .center)
				.onDisappear {
					ActivityMonitor.shared.onInactivity?()
				}
#else
			MainView()
#endif
		}
	}
}
