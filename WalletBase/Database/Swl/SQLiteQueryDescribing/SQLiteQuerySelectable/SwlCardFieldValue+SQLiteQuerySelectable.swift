//
//  SwlCardFieldValue+SQLiteQuerySelectable.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.CardFieldValue: SQLiteQuerySelectable {
	enum Column: String {
		case id
		case cardID
		case templateFieldID
		case valueString
	}

	static let columns: [Column] = [.id, .cardID, .templateFieldID, .valueString]
	static let table = SwlDatabase.Tables.cardFieldValues
	static let primary: Column = .id
	func encode() -> [Column: SQLiteDataType] {
		[
			.id: id.encoded,
			.cardID: cardId.encoded,
			.templateFieldID: templateFieldId.encoded,
			.valueString: .nullableBlob(value: .init(arrayValue: value)),
		]
	}
}
