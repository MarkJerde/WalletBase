//
//  CardValuesComposite.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/3/21.
//

import Foundation

struct CardValuesComposite: CardViewItem {
	var name: String
	var values: [CardValue]

	struct FieldValue {
		let field: SwlDatabase.SwlTemplateField?
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
				case password = 4
				case plaintext = 12345
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
			return CardValuesComposite.Value(name: database.decryptString(bytes: field?.name ?? []) ?? "",
			                                 hidePlaintext: fieldType == .password,
			                                 encryptedValue: cardValue.value) { encrypted in
				database.decryptString(bytes: encrypted)
			}
		}
		let result = CardValuesComposite(name: database.decryptString(bytes: card.name) ?? "",
		                                 values: values)
		return result
	}

	struct CardValue: CardViewValue {
		var name: String
		var hidePlaintext: Bool
		var encryptedValue: [UInt8]
		var decryptor: ([UInt8]) -> String?

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
}
