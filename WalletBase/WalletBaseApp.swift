//
//  WalletBaseApp.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/10/21.
//

import SwiftUI

@main
enum AppMainSelector {
	static func main() {
		if #available(OSX 11.0, *) {
			WalletBaseApp.main()
		} else {
			WalletBaseCompatibilityApp.main()
		}
	}
}

class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationWillTerminate(_ notification: Notification) {
		// Signal inactivity to lock the wallet.
		ActivityMonitor.shared.onInactivity?()
	}
}

class CompatibilityAppDelegate: AppDelegate {
	// Thanks, javier! https://swiftui-lab.com/backward-compatibility/
	var window: NSWindow!

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Create the SwiftUI view that provides the window contents.
		let contentView = MainView(appState: .init())
			.frame(width: 976, height: 576, alignment: .center)

		// Create the window and set the content view.
		window = NSWindow(
			contentRect: NSRect(x: 0, y: 0, width: 976, height: 576),
			styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
			backing: .buffered, defer: false)

		window.title = "WalletBase"
		window.minSize = .init(width: 976, height: 576)
		window.isReleasedWhenClosed = false
		window.center()
		window.setFrameAutosaveName("Main Window")
		window.contentView = NSHostingView(rootView: contentView)
		window.makeKeyAndOrderFront(nil)

		// window.setFrame(.init(origin: .init(x: window.frame.origin.x, y: window.frame.origin.y), size: .init(width: 976, height: 576)), display: true, animate: true)
	}
}

enum WalletBaseCompatibilityApp {
	static let appDelegate = CompatibilityAppDelegate()
	static func main() {
		NSApplication.shared.setActivationPolicy(.regular)

		let menu = AppMenu()
		NSApplication.shared.mainMenu = menu
		// let nib = NSNib(nibNamed: NSNib.Name("MainMenu"), bundle: Bundle.main)
		// nib?.instantiate(withOwner: NSApplication.shared, topLevelObjects: nil)

		NSApp.delegate = Self.appDelegate
		NSApp.activate(ignoringOtherApps: true)
		NSApp.run()
	}

	private class AppMenu: NSMenu {
		// Thanks, Ryan! https://medium.com/@theboi/macos-apps-without-storyboard-or-xib-menu-bar-in-swift-5-menubar-and-toolbar-6f6f2fa39ccb
		private lazy var applicationName = ProcessInfo.processInfo.processName

		override init(title: String) {
			super.init(title: title)
			let menuItemOne = NSMenuItem()
			menuItemOne.submenu = NSMenu(title: "menuItemOne")
			menuItemOne.submenu?.items = [NSMenuItem(title: "Quit \(applicationName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")]
			items = [menuItemOne]
		}

		required init(coder: NSCoder) {
			super.init(coder: coder)
		}
	}
}

@available(OSX 11.0, *)
struct WalletBaseApp: App {
#if os(macOS)
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif

	@StateObject var appState = AppState()

	var body: some Scene {
		WindowGroup {
#if os(macOS)
			MainView(appState: appState)
				.frame(minWidth: 976, maxWidth: .infinity, minHeight: 576, maxHeight: .infinity, alignment: .center)
				.onDisappear {
					ActivityMonitor.shared.onInactivity?()
				}
#else
			MainView(appState: appState)
#endif
		}
		.commands {
			CommandGroup(replacing: .newItem) {
				Button(action: {
					self.appState.showPromptForNewCard()
				}, label: {
					Text("New Card")
				})
				.disabled(!appState.canCreateNewCard)
				.keyboardShortcut("N")
				Button(action: {
					self.appState.showPromptForNewFolder()
				}, label: {
					Text("New Folder")
				})
				.disabled(!appState.canCreateNewFolder)
				.keyboardShortcut("N", modifiers: [.shift, .command])
				// I don't really want a New Window menu item. This just makes a good note for how to do modifiers and what the normal keyboard shortcut for New Window is.
				/* Button(action: {
				 	print("Menu Button selected")
				 }, label: {
				 	Text("New Window")
				 })
				 .keyboardShortcut("N", modifiers: [.option, .command]) */
			}
		}
	}
}
