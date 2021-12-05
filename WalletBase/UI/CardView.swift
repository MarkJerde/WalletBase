//
//  CardView.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/2/21.
//

import SwiftUI

protocol CardViewValue: Hashable {
	var name: String { get }
	var hidePlaintext: Bool { get }
	var decryptedValue: String? { get }
}

protocol CardViewItem: Hashable {
	associatedtype Value: CardViewValue
	var name: String { get }
	var values: [Value] { get }
}

struct CardView<Item: CardViewItem>: View {
	@Binding var item: Item?
	let onBackTap: () -> Void

	var body: some View {
		NavigationFrame(currentName: item?.name ?? "",
		                onBackTap: onBackTap) {
			ScrollView {
				VStack {
					ForEach(item?.values ?? [], id: \.self) { item in
						HStack {
							Text(item.name)
							Spacer()
							Button {
								// FIXME: Do something
							} label: {
								Text(item.hidePlaintext ? "********" : (item.decryptedValue ?? ""))
							}
							Button("Copy") {
								if let value = item.decryptedValue {
									let pasteboard = NSPasteboard.general
									pasteboard.declareTypes([.string], owner: nil)
									pasteboard.setString(value, forType: .string)
									// FIXME: clear pasteboard after N seconds
								}
							}
							.background(Color.gray)
						}
					}
				}
				.padding(20)
			}
		}
	}
}

struct CardView_Previews_Value: CardViewValue {
	var name: String
	var hidePlaintext: Bool
	var decryptedValue: String?
}

struct CardView_Previews_Item: CardViewItem {
	var name: String
	var values: [CardView_Previews_Value]
}

struct CardView_Previews: PreviewProvider {
	static var previews: some View {
		CardView(item: .constant(CardView_Previews_Item(name: "Counting", values: [
			.init(name: "One", hidePlaintext: false, decryptedValue: "Uno"),
			.init(name: "Two", hidePlaintext: true, decryptedValue: "Dos"),
			.init(name: "Three", hidePlaintext: false, decryptedValue: "Tres"),
			.init(name: "Four", hidePlaintext: true, decryptedValue: "Cuatro"),
		]))) {
			NSLog("Tapped back")
		}
	}
}
