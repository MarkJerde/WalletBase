//
//  NavigationFrame.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/2/21.
//

import Combine
import SwiftUI

struct NavigationFrame<Content>: View where Content: View {
	/*@Binding */var currentName: String?
	let onBackTap: () -> Void
	let onPreviousTap: (() -> Void)?
	let onNextTap: (() -> Void)?
	let onSearch: ((String) -> Void)?
	@ViewBuilder var content: () -> Content

	@State private var searchTerm = ""

	var body: some View {
		VStack {
			HStack {
				if currentName != nil {
					Button {
						onBackTap()
					} label: {
						Image.image(systemName: "arrow.backward",
						            color: .black,
						            size: 12)
					}
					.frame(height: 50)
				}
				Spacer(minLength: 50)
				if let onSearch = onSearch {
					TextField("Search...", text: $searchTerm)
						.overlay(
							RoundedRectangle(cornerRadius: 4)
								.stroke(Color.white, lineWidth: 2)
						)
						.onReceive(Just(searchTerm)) { _ in
							onSearch(searchTerm)
						}
				}
				Spacer(minLength: 50)
				if let currentName = currentName {
					if let onPreviousTap = onPreviousTap {
						Button {
							onPreviousTap()
						} label: {
							Image.image(systemName: "chevron.backward",
							            color: .black,
							            size: 12)
						}
						.frame(height: 50)
					}
					Text(currentName)
						.foregroundColor(.white)
					if let onNextTap = onNextTap {
						Button {
							onNextTap()
						} label: {
							Image.image(systemName: "chevron.forward",
							            color: .black,
							            size: 12)
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
		} onSearch: { string in
			NSLog("Searching for \(string)")
		} content: {
			Image.image(systemName: "creditcard",
			            color: .black,
			            size: 30)
		}
	}
}
