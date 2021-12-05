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
					Text(currentName)
						.foregroundColor(.white)
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
		} content: {
			Image(systemName: "creditcard")
		}
	}
}
