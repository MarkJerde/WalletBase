//
//  CardValue.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/6/21.
//

import SwiftUI

struct CardValue<Item: CardViewValue>: View {
	internal init(item: Item) {
		self.item = item
		_value = State(initialValue: item.hidePlaintext ? "********" : (item.decryptedValue ?? ""))
		_isEncrypted = State(initialValue: item.hidePlaintext)
	}

	let item: Item
	@State var value: String
	@State var isEncrypted: Bool
	@State var isActive: Bool = false
	var body: some View {
		HStack {
			Text(item.name)
				.padding()
			Spacer()
			Text(value)
				.padding()
			Button {
				if let value = item.decryptedValue {
					let pasteboard = NSPasteboard.general
					pasteboard.declareTypes([.string], owner: nil)
					pasteboard.setString(value, forType: .string)
					// FIXME: clear pasteboard after N seconds
				}
			} label: {
				Text("Copy")
			}
			.buttonStyle(CopyButtonStyle())
		}
		.background(Color.white.opacity(0.02)) // Minimum non-hidden opacity because hidden and clear items are not tappable in SwiftUI, or at least not as tappable.
		.onTapGesture {
			if item.hidePlaintext {
				if isEncrypted {
					value = item.decryptedValue ?? ""
				} else {
					value = "********"
				}
				isEncrypted = !isEncrypted
			} else if item.isURL,
			          let url = URL(string: value)
			{
				isActive = true
				NSWorkspace.shared.open(url, configuration: .init()) { _, _ in
					isActive = false
				}
			}
		}
		.overlay(
			RoundedRectangle(cornerRadius: 4)
				.stroke(isActive ? Color.blue : Color.gray, lineWidth: 2)
		)
	}

	private struct CopyButtonStyle: ButtonStyle {
		func makeBody(configuration: Self.Configuration) -> some View {
			configuration.label
				.padding()
				.background(configuration.isPressed ? Color.gray : Color.white)
		}
	}
}

struct CardValue_Previews: PreviewProvider {
	static var previews: some View {
		VStack(spacing: 8) {
			CardValue(item: CardView_Previews_Value(name: "One", hidePlaintext: false, isURL: false, decryptedValue: "Uno"))
			CardValue(item: CardView_Previews_Value(name: "Two", hidePlaintext: true, isURL: false, decryptedValue: "Dos"))
			CardValue(item: CardView_Previews_Value(name: "Three", hidePlaintext: false, isURL: false, decryptedValue: "Tres"))
		}
		.padding()
	}
}
