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
	var isURL: Bool { get }
	var decryptedValue: String? { get }
}

protocol CardViewAttachment: Hashable {
	var decryptedName: String? { get }
	var decryptedData: Data? { get }
}

protocol CardViewItem: Hashable {
	associatedtype Value: CardViewValue
	associatedtype Attachment: CardViewAttachment
	var name: String { get }
	var values: [Value] { get }
	var attachments: [Attachment] { get }
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
						CardValue(item: item)
					}
				}
				.padding(20)
				LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 20) {
					ForEach(item?.attachments ?? [], id: \.self) { item in
						VStack {
							Image(systemName: "doc.text")
								.font(.system(size: 30))
								.foregroundColor(.gray)
								.frame(width: 50, height: 50)
							Text(item.decryptedName ?? "???")
						}
						.onTapGesture {
							let alert = NSAlert()
							alert.messageText = "Save compressed attachment?"
							alert.informativeText = "Attachments are compressed, though it's not clear what compression was used. But at least it's decrypted. Do you still want to save?"
							alert.alertStyle = .warning
							alert.addButton(withTitle: "OK")
							alert.addButton(withTitle: "Cancel")
							guard alert.runModal() == .alertFirstButtonReturn else { return }

							let dialog = NSSavePanel()

							dialog.title = "Save attachment"
							dialog.nameFieldStringValue = item.decryptedName ?? "Unknown"
							dialog.canCreateDirectories = true
							dialog.showsResizeIndicator = true

							guard dialog.runModal() == .OK,
							      let url = dialog.url else { return }

							try? item.decryptedData?.write(to: url)
						}
					}
				}
			}
		}
	}
}

struct CardView_Previews_Value: CardViewValue {
	var name: String
	var hidePlaintext: Bool
	var isURL: Bool
	var decryptedValue: String?
}

struct CardView_Previews_Attachment: CardViewAttachment {
	var decryptedName: String?
	var decryptedData: Data?
}

struct CardView_Previews_Item: CardViewItem {
	var name: String
	var values: [CardView_Previews_Value]
	var attachments: [CardView_Previews_Attachment]
}

struct CardView_Previews: PreviewProvider {
	static var previews: some View {
		CardView(item: .constant(CardView_Previews_Item(name: "Counting", values: [
			.init(name: "One", hidePlaintext: false, isURL: false, decryptedValue: "Uno"),
			.init(name: "Two", hidePlaintext: true, isURL: false, decryptedValue: "Dos"),
			.init(name: "Three", hidePlaintext: false, isURL: false, decryptedValue: "Tres"),
			.init(name: "Four", hidePlaintext: true, isURL: false, decryptedValue: "Cuatro"),
		], attachments: [
			.init(decryptedName: "Able", decryptedData: "Baker Charlie".data(using: .utf8)),
		]))) {
			NSLog("Tapped back")
		}
	}
}
