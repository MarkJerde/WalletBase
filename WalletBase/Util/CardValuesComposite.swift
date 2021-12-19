//
//  CardValuesComposite.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/3/21.
//

import Foundation

struct CardValuesComposite: CardViewItem {
	let name: String
	let values: [CardValue]
	let description: CardDescription?
	let attachments: [CardAttachment]

	struct FieldValue {
		let field: SwlDatabase.TemplateField?
		let value: SwlDatabase.CardFieldValue
	}

	static func card(for card: SwlDatabase.Card, database: SwlDatabase) -> Self? {
		let cardValues = database.fieldValues(in: card)
		let fieldValues: [FieldValue] = cardValues.map { cardValue in
			let field = database.templateField(forId: cardValue.templateFieldId)
			return FieldValue(field: field, value: cardValue)
		}.sorted {
			($0.field?.priority ?? 9999) < ($1.field?.priority ?? 9999)
		}
		let values: [CardValuesComposite.Value] = fieldValues.map { fieldValue in
			let field = fieldValue.field
			let cardValue = fieldValue.value
			enum FieldType: Int32 {
				case plaintext = 1
				case idNumber = 2
				case name = 3
				case password = 4
				case url = 6
				case email = 7
				case phone = 8
			}
			let fieldType: FieldType
			if let type = field?.fieldTypeId {
				if let type = FieldType(rawValue: type) {
					fieldType = type
				} else {
					fieldType = .plaintext
				}
			} else {
				fieldType = .password
			}
			let name = database.decryptString(bytes: field?.name ?? []) ?? ""
			return CardValuesComposite.Value(name: name,
			                                 hidePlaintext: fieldType == .password,
			                                 isURL: fieldType == .url,
			                                 encryptedValue: cardValue.value) { encrypted in
				database.decryptString(bytes: encrypted)
			}
		}

		let cardDescription = database.description(in: card)
		let description: CardDescription?
		if let cardDescription = cardDescription?.description {
			description = CardDescription(encryptedDescription: cardDescription) { encrypted in
				database.decryptString(bytes: encrypted)
			}
		} else {
			description = nil
		}

		let cardAttachments = database.attachments(in: card)
		let attachments = cardAttachments.map { CardAttachment(encryptedName: $0.name,
		                                                       encryptedData: $0.data) { encrypted in
				database.decryptString(bytes: encrypted)
			} dataDecryptor: { encrypted in
				database.decryptData(bytes: encrypted)
			}
		}

		let result = CardValuesComposite(name: database.decryptString(bytes: card.name) ?? "",
		                                 values: values,
		                                 description: description,
		                                 attachments: attachments)
		return result
	}

	struct CardValue: CardViewValue {
		let name: String
		let hidePlaintext: Bool
		let isURL: Bool
		let encryptedValue: [UInt8]
		let decryptor: ([UInt8]) -> String?

		var decryptedValue: String? {
			decryptor(encryptedValue)
		}

		static func == (lhs: CardValuesComposite.CardValue, rhs: CardValuesComposite.CardValue) -> Bool {
			lhs.name == rhs.name
				&& lhs.hidePlaintext == rhs.hidePlaintext
				&& lhs.encryptedValue == rhs.encryptedValue
		}

		func hash(into hasher: inout Hasher) {
			name.hash(into: &hasher)
			hidePlaintext.hash(into: &hasher)
			encryptedValue.hash(into: &hasher)
		}
	}

	struct CardDescription: CardViewDescription {
		let encryptedDescription: [UInt8]
		let decryptor: ([UInt8]) -> String?

		static func == (lhs: CardValuesComposite.CardDescription, rhs: CardValuesComposite.CardDescription) -> Bool {
			lhs.encryptedDescription == rhs.encryptedDescription
		}

		func hash(into hasher: inout Hasher) {
			encryptedDescription.hash(into: &hasher)
		}

		var decryptedDescription: String? {
			decryptor(encryptedDescription)
		}
	}

	struct CardAttachment: CardViewAttachment {
		let encryptedName: [UInt8]
		let encryptedData: [UInt8]
		let decryptor: ([UInt8]) -> String?
		let dataDecryptor: ([UInt8]) -> Data?

		static func == (lhs: CardValuesComposite.CardAttachment, rhs: CardValuesComposite.CardAttachment) -> Bool {
			lhs.encryptedName == rhs.encryptedName
				&& lhs.encryptedData == rhs.encryptedData
		}

		func hash(into hasher: inout Hasher) {
			encryptedName.hash(into: &hasher)
			encryptedData.hash(into: &hasher)
		}

		var decryptedName: String? {
			decryptor(encryptedName)
		}

		var decryptedData: Data? {
			dataDecryptor(encryptedData)
		}
	}
}
