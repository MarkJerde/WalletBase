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
	associatedtype IDType: Hashable
	var name: String { get }
	var values: [Value] { get }
	var getTemplateValues: () -> [Value] { get }
	var description: Description? { get }
	var attachments: [Attachment] { get }
	var id: IDType { get }
}

extension CardViewItem {
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.name == rhs.name
			&& lhs.values == rhs.values
			&& lhs.description == rhs.description
			&& lhs.attachments == rhs.attachments
			&& lhs.id == rhs.id
	}

	func hash(into hasher: inout Hasher) {
		name.hash(into: &hasher)
		values.hash(into: &hasher)
		description.hash(into: &hasher)
		attachments.hash(into: &hasher)
		id.hash(into: &hasher)
	}
}

struct CardView<Item: CardViewItem>: View {
	@Binding var item: Item?
	@State var templateValues: [Item.Value] = []
	let onBackTap: () -> Void
	let onPreviousTap: (() -> Void)?
	let onNextTap: (() -> Void)?
	let onSave: (([Item.Value: String], String?) -> Bool)?

	@State private var isEditing = false {
		didSet {
			if isEditing {
				// Get templateValues
				templateValues = item?.getTemplateValues() ?? []
				editableDescription = item?.description?.decryptedDescription ?? ""
			} else {
				templateValues = []
				edits = [:]
				editableDescription = ""
			}
		}
	}

	@State private var edits: [Item.Value: String] = [:]
	@State private var editableDescription: String = ""

	private func isOkayToNavigate(completion: @escaping (Bool) -> Void) {
		guard isEditing,
		      !edits.isEmpty
		else {
			completion(true)
			return
		}

		Alert.savePendingChanges.show { response in
			guard response != "Cancel" else {
				completion(false)
				return
			}
			if response == "Save" {
				guard save() else {
					completion(false)
					return
				}
			}
			completion(true)
		}
	}

	private func save() -> Bool {
		guard let onSave,
		      isEditing else { return true }

		// A nil description indicates no description changes.
		var description: String?
		if editableDescription != (item?.description?.decryptedDescription ?? "") {
			// Set description to communicate changes.
			description = editableDescription
		}
		guard onSave(edits, description) else { return false }
		isEditing = false

		return true
	}

	var body: some View {
		NavigationFrame(currentName: item?.name ?? "",
		                onBackTap: {
		                	isOkayToNavigate { isOkay in
		                		guard isOkay else { return }
		                		onBackTap()
		                	}
		                },
		                onNewTap: nil,
		                onPreviousTap: (onPreviousTap == nil) ? nil : {
		                	isOkayToNavigate { isOkay in
		                		guard isOkay else { return }
		                		onPreviousTap?()
		                	}
		                },
		                onNextTap: (onNextTap == nil) ? nil : {
		                	isOkayToNavigate { isOkay in
		                		guard isOkay else { return }
		                		onNextTap?()
		                	}
		                },
		                onSearch: nil) {
			ScrollView {
				if onSave != nil {
					if !isEditing {
						Button("Edit") {
							isEditing = true
						}
					} else {
						HStack {
							Button("Cancel") {
								isEditing = false
							}
							Button("Save") {
								_ = save()
							}
						}
					}
				}
				VStack {
					ForEach((isEditing ? templateValues : item?.values) ?? [], id: \.self) { item in
						CardValue(item: item,
						          isEditing: isEditing,
						          onSet: { value in
						          	edits[item] = value
						          })
					}
				}
				.padding([.horizontal], 20)
				if isEditing ||
					(item?.description?.decryptedDescription != nil
						&& !(item?.description?.decryptedDescription)!.isEmpty)
				{
					// TextField is used to provide the ability to copy & paste, but it has the downside of making the content editable and of adding a light shadow frame.
					MultilineTextField("", text: isEditing ? $editableDescription : .constant((item?.description?.decryptedDescription)!))
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
				Alert.saveCompressedAttachement.show { response in
					guard response == "OK" else { return }

					let dialog = NSSavePanel()

					dialog.title = "Save attachment"
					dialog.nameFieldStringValue = item.decryptedName ?? "Unknown"
					dialog.canCreateDirectories = true
					dialog.showsResizeIndicator = true

					guard dialog.runModal() == .OK,
					      let url = dialog.url else { return }

					// These are compressed with zlib and then wrapped with some custom stuff.
					// 4 bytes uncompressed length, little endian.
					// 2 bytes something (78 9c in all small and large examples observed)
					// zlib
					// 4 bytes something
					// 0x06
					guard let decryptedData = item.decryptedData,
					      decryptedData.count > 11 else { return }

					let zlibData = decryptedData.subdata(in: 6 ..< (decryptedData.count - 5)) as NSData
					try? zlibData.decompressed(using: .zlib).write(to: url)
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
	let getTemplateValues: () -> [CardView_Previews_Value]
	var description: CardView_Previews_Description?
	var attachments: [CardView_Previews_Attachment]
	var id = UUID()
}

struct CardView_Previews: PreviewProvider {
	static let values: [CardView_Previews_Value] = [
		.init(name: "One", hidePlaintext: false, isURL: false, decryptedValue: "Uno"),
		.init(name: "Two", hidePlaintext: true, isURL: false, decryptedValue: "Dos"),
		.init(name: "Three", hidePlaintext: false, isURL: false, decryptedValue: "Tres"),
		.init(name: "Four", hidePlaintext: true, isURL: false, decryptedValue: "Cuatro"),
	]

	static var previews: some View {
		CardView(item: .constant(CardView_Previews_Item(name: "Counting", values: values, getTemplateValues: {
				values
			},
			description: CardView_Previews_Description(decryptedDescription: "This is the description text.\nIt has a second line.\nIt also has a really long line that mentions that the encrypted items above decrypt to Dos and Cuator.\n\nAfter a blank fourth line, it ends with a fifth line."),
			attachments: [
				.init(decryptedName: "Able", decryptedData: "Baker Charlie".data(using: .utf8)),
			]))) {
				NSLog("Tapped back")
			}
			onPreviousTap: {}
			onNextTap: {}
			onSave: { _, _ in
				NSLog("Tapped Save")
				return true
			}
			.frame(height: 700.0)
	}
}
