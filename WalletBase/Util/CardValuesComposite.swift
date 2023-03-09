//
//  CardValuesComposite.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/3/21.
//

import Foundation

struct CardValuesComposite<IDType>: CardViewItem where IDType: Hashable {
	let name: String
	let values: [CardValue]
	let getTemplateValues: () -> [CardValue]
	let description: CardDescription?
	let attachments: [CardAttachment]
	let id: IDType

	struct FieldValue {
		let field: SwlDatabase.TemplateField?
		let value: SwlDatabase.CardFieldValue
	}

	static func card(for card: SwlDatabase.Card, database: SwlDatabase) -> CardValuesComposite<SwlDatabase.SwlID>? {
		let cardValues = database.fieldValues(in: card)
		let fieldValues: [FieldValue] = cardValues.map { cardValue in
			let field = database.templateField(forId: cardValue.templateFieldId)
			return FieldValue(field: field, value: cardValue)
		}.sorted {
			($0.field?.priority ?? 9999) < ($1.field?.priority ?? 9999)
		}
		let values: [CardValuesComposite<SwlDatabase.SwlID>.Value] = fieldValues.map { fieldValue in
			let field = fieldValue.field
			let cardValue = fieldValue.value
			let fieldType: SwlDatabase.TemplateField.FieldType
			if let type = field?.fieldTypeId {
				fieldType = SwlDatabase.TemplateField.FieldType(rawValue: type) ?? .plaintext
			} else {
				fieldType = .password
			}
			let name = database.decryptString(bytes: field?.name ?? []) ?? ""
			return CardValuesComposite<SwlDatabase.SwlID>.Value(id: cardValue.id,
			                                                    templateFieldId: fieldValue.value.templateFieldId,
			                                                    name: name,
			                                                    hidePlaintext: fieldType == .password,
			                                                    isURL: fieldType == .url,
			                                                    encryptedValue: cardValue.value) { encrypted in
				ActivityMonitor.shared.didActivity()
				return database.decryptString(bytes: encrypted)
			}
		}

		let cardDescription = database.description(in: card)
		let description: CardValuesComposite<SwlDatabase.SwlID>.CardDescription?
		if let cardDescription = cardDescription?.description {
			description = CardValuesComposite<SwlDatabase.SwlID>.CardDescription(encryptedDescription: cardDescription) { encrypted in
				ActivityMonitor.shared.didActivity()
				return database.decryptString(bytes: encrypted)
			}
		} else {
			description = nil
		}

		let cardAttachments = database.attachments(in: card)
		let attachments = cardAttachments.map { CardValuesComposite<SwlDatabase.SwlID>.CardAttachment(encryptedName: $0.name,
		                                                                                              encryptedData: $0.data) { encrypted in
				ActivityMonitor.shared.didActivity()
				return database.decryptString(bytes: encrypted)
			} dataDecryptor: { encrypted in
				ActivityMonitor.shared.didActivity()
				return database.decryptData(bytes: encrypted)
			}
		}

		let result = CardValuesComposite<SwlDatabase.SwlID>(name: database.decryptString(bytes: card.name) ?? "",
		                                                    values: values,
		                                                    getTemplateValues: {
		                                                    	let fields = database.templateFields(forTemplateId: card.templateID)
		                                                    		.sorted(by: \.priority)
		                                                    	guard !fields.isEmpty else { return values }
		                                                    	return fields
		                                                    		.sorted { $0.priority < $1.priority }
		                                                    		.map { (field: SwlDatabase.TemplateField) -> FieldValue in
		                                                    			guard let fieldValue = fieldValues.first(where: { fieldValue in
		                                                    				fieldValue.field?.id == field.id
		                                                    			}) else {
		                                                    				return FieldValue(field: field,
		                                                    				                  value: .init(id: .init(value: [], hexString: "0x0"),
		                                                    				                               cardId: card.id,
		                                                    				                               templateFieldId: field.id,
		                                                    				                               value: []))
		                                                    			}
		                                                    			return fieldValue
		                                                    		}
		                                                    		.map { fieldValue in
		                                                    			let field = fieldValue.field
		                                                    			let cardValue = fieldValue.value
		                                                    			let fieldType: SwlDatabase.TemplateField.FieldType
		                                                    			if let type = field?.fieldTypeId {
		                                                    				fieldType = SwlDatabase.TemplateField.FieldType(rawValue: type) ?? .plaintext
		                                                    			} else {
		                                                    				fieldType = .password
		                                                    			}
		                                                    			let name = database.decryptString(bytes: field?.name ?? []) ?? ""
		                                                    			return CardValuesComposite<SwlDatabase.SwlID>.Value(id: cardValue.id,
		                                                    			                                                    templateFieldId: fieldValue.value.templateFieldId,
		                                                    			                                                    name: name,
		                                                    			                                                    hidePlaintext: fieldType == .password,
		                                                    			                                                    isURL: fieldType == .url,
		                                                    			                                                    encryptedValue: cardValue.value) { encrypted in
		                                                    				ActivityMonitor.shared.didActivity()
		                                                    				return database.decryptString(bytes: encrypted)
		                                                    			}
		                                                    		}
		                                                    },
		                                                    description: description,
		                                                    attachments: attachments,
		                                                    id: card.id)
		return result
	}

	struct CardValue: CardViewValue {
		let id: IDType
		let templateFieldId: IDType
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
