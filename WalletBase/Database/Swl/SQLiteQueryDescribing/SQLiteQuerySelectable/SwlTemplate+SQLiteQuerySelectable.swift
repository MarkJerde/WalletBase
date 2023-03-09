//
//  SwlTemplate+SQLiteQuerySelectable.swift
//  WalletBase
//
//  Created by Mark Jerde on 2/23/23.
//

import Foundation

extension SwlDatabase.Template: SQLiteQuerySelectable {
	enum Column: String, CaseIterable {
		case id
		case name
		case description
		case cardViewID
		case syncID
		case createSyncID
	}

	static let columns: [Column] = Column.allCases
	static let table = SwlDatabase.Tables.templates
	func encode() -> [Column: SQLiteDataType] {
		[
			.id: id.encoded,
			.name: .blob(value: .init(arrayValue: name)),
			.description: .nullableBlob(value: (description == nil) ? nil : .init(arrayValue: description!)),
			.cardViewID: cardViewID.encoded,
			.syncID: .integer(value: -1), // (default: -1)
			.createSyncID: .integer(value: -1), // (default: -1)
		]
	}
}
