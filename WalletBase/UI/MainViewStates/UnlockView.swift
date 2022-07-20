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
