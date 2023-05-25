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
#if DEBUG
				.onAppear {
					guard file.hasSuffix("Sample.swl"),
					      !Self.didAutoTapUnlockForSampleWallet else { return }
					Self.didAutoTapUnlockForSampleWallet = true
					DispatchQueue.main.async {
						self.unlock()
					}
				}
#endif
			.compatibilityKeyboardShortcut(.defaultAction) { window in
				guard let firstSubviews = (window.contentViewController?.view ?? window.contentView)?.subviews,
				      let secondSubviews = firstSubviews.prefix(2).last?.subviews,
				      let button = secondSubviews.first as? NSButton else { return nil }
				return button
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

#if DEBUG
	static var didAutoTapUnlockForSampleWallet = false
#endif
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
