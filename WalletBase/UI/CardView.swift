//
//  CardView.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/2/21.
//

import SwiftUI

extension NSTextField {
	// Inhibit the blue outline when selecting description text.
	override open var focusRingType: NSFocusRingType {
		get { .none }
		set {}
	}
}

protocol CardViewValue: Hashable {
	var name: String { get }
	var hidePlaintext: Bool { get }
	var isURL: Bool { get }
	var decryptedValue: String? { get }
}

protocol CardViewDescription: Hashable {
	var decryptedDescription: String? { get }
}

protocol CardViewAttachment: Hashable {
	var decryptedName: String? { get }
	var decryptedData: Data? { get }
}

protocol CardViewItem: Hashable {
	associatedtype Value: CardViewValue
	associatedtype Description: CardViewDescription
	associatedtype Attachment: CardViewAttachment
	var name: String { get }
	var values: [Value] { get }
	var description: Description? { get }
	var attachments: [Attachment] { get }
}

struct CardView<Item: CardViewItem>: View {
	@Binding var item: Item?
	let onBackTap: () -> Void
	let onPreviousTap: (() -> Void)?
	let onNextTap: (() -> Void)?
	let onSave: (([Item.Value: String]) -> Bool)?

	@State private var isEditing = false
	@State private var edits: [Item.Value: String] = [:]

	var body: some View {
		NavigationFrame(currentName: item?.name ?? "",
		                onBackTap: onBackTap,
		                onPreviousTap: onPreviousTap,
		                onNextTap: onNextTap,
		                onSearch: nil) {
			ScrollView {
				if let onSave = onSave {
					if !isEditing {
						Button("Edit") {
							isEditing = true
						}
					} else {
						HStack {
							Button("Cancel") {
								isEditing = false
								edits = [:]
							}
							Button("Save") {
								guard onSave(edits) else { return }
								isEditing = false
								edits = [:]
							}
						}
					}
				}
				VStack {
					ForEach(item?.values ?? [], id: \.self) { item in
						CardValue(item: item,
						          isEditing: isEditing,
						          onSet: { value in
						          	edits[item] = value
						          })
					}
				}
				.padding([.horizontal], 20)
				if let description = item?.description?.decryptedDescription {
					// TextField is used to provide the ability to copy & paste, but it has the downside of making the content editable and of adding a light shadow frame.
					TextField("", text: .constant(description))
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
						.padding(20)
						.background(Color(NSColor.textBackgroundColor))
						.overlay(
							RoundedRectangle(cornerRadius: 4)
								.stroke(Color.gray, lineWidth: 2)
						)
						.padding(.top, 16)
						.padding(.horizontal, 20)
				}
				CompatibilityVGrid(data: item?.attachments ?? [], id: \.self) { item in
					AttachmentsGridItem(item: item)
				}
				.padding(.top, 10)
			}
		}
	}

	private struct AttachmentsGridItem: View {
		let item: Item.Attachment

		var body: some View {
			VStack {
				Image.image(systemName: "doc.text",
				            color: .gray,
				            size: 30)
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

struct CardView_Previews_Value: CardViewValue {
	var name: String
	var hidePlaintext: Bool
	var isURL: Bool
	var decryptedValue: String?
}

struct CardView_Previews_Description: CardViewDescription {
	var decryptedDescription: String?
}

struct CardView_Previews_Attachment: CardViewAttachment {
	var decryptedName: String?
	var decryptedData: Data?
}

struct CardView_Previews_Item: CardViewItem {
	var name: String
	var values: [CardView_Previews_Value]
	var description: CardView_Previews_Description?
	var attachments: [CardView_Previews_Attachment]
}

struct CardView_Previews: PreviewProvider {
	static var previews: some View {
		CardView(item: .constant(CardView_Previews_Item(name: "Counting", values: [
				.init(name: "One", hidePlaintext: false, isURL: false, decryptedValue: "Uno"),
				.init(name: "Two", hidePlaintext: true, isURL: false, decryptedValue: "Dos"),
				.init(name: "Three", hidePlaintext: false, isURL: false, decryptedValue: "Tres"),
				.init(name: "Four", hidePlaintext: true, isURL: false, decryptedValue: "Cuatro"),
			],
			description: CardView_Previews_Description(decryptedDescription: "This is the description text.\nIt has a second line.\nIt also has a really long line that mentions that the encrypted items above decrypt to Dos and Cuator.\n\nAfter a blank fourth line, it ends with a fifth line."),
			attachments: [
				.init(decryptedName: "Able", decryptedData: "Baker Charlie".data(using: .utf8)),
			]))) {
				NSLog("Tapped back")
			}
			onPreviousTap: {}
			onNextTap: {}
			onSave: { _ in
				NSLog("Tapped Save")
				return true
			}
			.frame(height: 700.0)
	}
}
