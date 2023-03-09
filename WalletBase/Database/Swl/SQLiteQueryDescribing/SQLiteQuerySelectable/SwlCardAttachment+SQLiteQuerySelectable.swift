//
//  SwlCardAttachment+SQLiteQuerySelectable.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.CardAttachment: SQLiteQuerySelectable {
	enum Column: String, CaseIterable {
		case id
		case cardID
		case name
		case data
	}

	static let columns: [Column] = [.id, .cardID, .name, .data]
	static let table = SwlDatabase.Tables.cardAttachments
	func encode() -> [Column: SQLiteDataType] {
		[
			.id: id.encoded,
			.cardID: cardId.encoded,
			.name: .blob(value: .init(arrayValue: name)),
			.data: .nullableBlob(value: .init(arrayValue: data)),
		]
	}
}
