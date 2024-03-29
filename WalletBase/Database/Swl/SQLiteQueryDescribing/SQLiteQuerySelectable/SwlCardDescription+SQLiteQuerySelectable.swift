//
//  SwlCardDescription+SQLiteQuerySelectable.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.CardDescription: SQLiteQuerySelectable {
	enum Column: String, CaseIterable {
		case id
		case description
	}

	static let columns: [Column] = [.id, .description]
	static let table = SwlDatabase.Tables.cards
	func encode() -> [Column: SQLiteDataType] {
		[
			.id: id.encoded,
			.description: .nullableBlob(value: descriptionItem),
		]
	}

	private var descriptionItem: SQLiteDataItem? {
		guard let description = description else { return nil }
		return SQLiteDataItem(arrayValue: description)
	}
}
