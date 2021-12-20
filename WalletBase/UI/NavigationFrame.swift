//
//  NavigationFrame.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/2/21.
//

import SwiftUI

struct NavigationFrame<Content>: View where Content: View {
	/*@Binding */var currentName: String?
	let onBackTap: () -> Void
	let onPreviousTap: (() -> Void)?
	let onNextTap: (() -> Void)?
	@ViewBuilder var content: () -> Content

	var body: some View {
		VStack {
			HStack {
				if let currentName = currentName {
					Button {
						onBackTap()
					} label: {
						Image(systemName: "arrow.backward")
							.foregroundColor(.black)
					}
					.frame(height: 50)
					Spacer()
					if let onPreviousTap = onPreviousTap {
						Button {
							onPreviousTap()
						} label: {
							Image(systemName: "chevron.backward")
								.foregroundColor(.black)
						}
						.frame(height: 50)
					}
					Text(currentName)
						.foregroundColor(.white)
					if let onNextTap = onNextTap {
						Button {
							onNextTap()
						} label: {
							Image(systemName: "chevron.forward")
								.foregroundColor(.black)
						}
						.frame(height: 50)
					}
				}
			}
			.padding([.leading, .trailing], 20)
			.frame(height: 50)
			.frame(maxWidth: .infinity)
			.background(Color.secondary)
			content()
		}
	}
}

struct NavigationFrame_Previews: PreviewProvider {
	static var previews: some View {
		NavigationFrame(currentName: "Sample Title") {
			NSLog("Tapped back")
		} onPreviousTap: {
			NSLog("Tapped previous")
		} onNextTap: {
			NSLog("Tapped next")
		} content: {
			Image(systemName: "creditcard")
		}
	}
}
