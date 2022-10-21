//
//  UnlockView.swift
//  WalletBase
//
//  Created by Mark Jerde on 7/19/22.
//

import SwiftUI

struct UnlockView: View {
	let file: String
	let unlock: () -> Void
	let importFile: (() -> Void)?

	var body: some View {
		VStack {
			Spacer()
			Text("Selected: \(file)")
			Button("Unlock") {
				unlock()
			}
			.onAppear {
				makeUnlockButtonFirstResponder()
			}
			Spacer()
			if let importFile = importFile {
				HStack {
					Text("Import this file for easier access:")
					Button("Import") {
						importFile()
					}
				}
			} else {
				Spacer()
			}
		}
		.padding(.all, 20)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}

	func makeUnlockButtonFirstResponder() {
		makeViewFirstResponder {
			guard let button = NSApplication.shared.mainWindow?.contentViewController?.view.subviews[1].subviews[0] as? NSButton else { return nil }
			// Adapted from https://stackoverflow.com/a/31730015
			let key = String(utf16CodeUnits: [unichar(NSCarriageReturnCharacter)], count: 1) as String
			button.keyEquivalent = key
			// Return the button even though it should be sufficiently setup, since that stops us from coming through here again.
			return button
		}
	}
}

struct UnlockView_Previews: PreviewProvider {
	static var previews: some View {
		UnlockView(file: "something.swl") {
			// No-op
		} importFile: {
			// No-op
		}
	}
}
