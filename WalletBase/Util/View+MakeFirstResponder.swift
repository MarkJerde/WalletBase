//
//  View+MakeFirstResponder.swift
//  WalletBase
//
//  Created by Mark Jerde on 10/20/22.
//

import SwiftUI

extension View {
	/// Takes a few attempts at making a view the first responder.
	///
	/// SwiftUI doesn't yet, as of macOS 11, have a way to make our SecureField a first responder. So this is an ugly hack that can be pretty well protected, depending on the quality of the closure, to avoid any ill effects because having the input fields (especially the password field) not auto-focus is pretty bad.
	///
	/// - Parameters:
	///   - attempt: The current attempt number. Five attempts will be made, stopping when exhausted or when the closure provides a view.
	///   - view: A closure to provide, if found, the view to make first responder.
	func makeViewFirstResponder(attempt: Int = 1, view: @escaping () -> NSView?) {
		// An interesting thing, is that when .onAppear{} was executed, the prior screen content was still what we would find in mainWindow. Testing shows that an async without delay is enough to get what we want, but try for up to 400 ms to find the view we want.
		DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds((attempt == 1) ? 0 : 100)) {
			guard let view = view()
			else {
				if attempt < 5 {
					self.makeViewFirstResponder(attempt: attempt + 1, view: view)
				}
				return
			}

			view.becomeFirstResponder()
		}
	}

	/// Takes a few attempts at making a button the default.
	///
	/// SwiftUI doesn't yet, as of macOS 11, have a way to make our Button the default. So this is an ugly hack that can be pretty well protected, depending on the quality of the closure, to avoid any ill effects because having the button not be default is pretty bad.
	/// - Parameter getButtonInWindow: A closure to provide, if found, the NSButton to make default.
	func makeButtonDefault(_ getButtonInWindow: @escaping (NSWindow) -> NSButton?) {
		let availableWindows: [NSWindow] = {
			var response: [NSWindow] = []
			let mainWindow = NSApplication.shared.mainWindow
			if let mainWindow = mainWindow {
				response.append(mainWindow)
			}
			let otherWindows = NSApplication.shared.windows.filter { $0 != mainWindow }
			response.append(contentsOf: otherWindows)
			return response
		}()

		makeViewFirstResponder {
			guard let button = availableWindows.compactMap({ getButtonInWindow($0) }).first else { return nil }
			// Adapted from https://stackoverflow.com/a/31730015
			let key = String(utf16CodeUnits: [unichar(NSCarriageReturnCharacter)], count: 1) as String
			button.keyEquivalent = key
			// Return the button even though it should be sufficiently setup, since that stops us from coming through here again.
			return button
		}
	}

#if DEBUG
	/// Prints all of the subviews of all windows as a debug aid in identifying the path to a window which should be made first responder.
	/// - Parameter prefix: A prefix, if desired, to place on the lines printed for identification sake.
	func printSubviewsOfAllWindows(prefix: String = "") {
		var num = 0
		for window in NSApplication.shared.windows {
			if let view = window.contentViewController?.view {
				printSubviews(of: view, prefix: "\(prefix)windows[\(num)]\(window == NSApplication.shared.mainWindow ? "(main)" : ""): ")
			}
			num += 1
		}
	}

	private func printSubviews(of view: NSView, prefix: String = "") {
		print("\(prefix) \(view)")
		for subview in view.subviews {
			printSubviews(of: subview, prefix: "\(prefix)  ")
		}
	}
#endif
}
