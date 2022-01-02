//
//  ActivityMonitor.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/27/21.
//

import Foundation

class ActivityMonitor {
	static let shared = ActivityMonitor()

	var onInactivity: (() -> Void)?

	init() {
		// Trigger inactivity if the screen is locked. Note that this notification is sent before the "Require password N after sleep or screen saver begins" time span has completed.
		DistributedNotificationCenter.default().addObserver(forName: .init("com.apple.screenIsLocked"),
		                                                    object: nil, queue: .main) { _ in
			self.onInactivity?()
		}
	}

	private var lastActivity = Date()

	func didActivity() {
		let now = Date()

		// Avoid dispatching a lot for a series of actions.
		guard now.timeIntervalSince(lastActivity) >= 2 else { return }
		lastActivity = now
		DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(600)) {
			guard self.lastActivity == now else { return }

			self.onInactivity?()
		}
	}
}
