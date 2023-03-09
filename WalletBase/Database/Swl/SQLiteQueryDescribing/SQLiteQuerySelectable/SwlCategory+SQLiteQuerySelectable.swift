//
//  SwlCategory+SQLiteQuerySelectable.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.Category: SQLiteQuerySelectable {
	enum Column: String, CaseIterable {
		case id
		case name
		case parentCategoryID
	}

	static let columns: [Column] = [.id, .name, .parentCategoryID]
	static let table = SwlDatabase.Tables.categories
	func encode() -> [Column: SQLiteDataType] {
		[
			.id: id.encoded,
			.name: .blob(value: .init(arrayValue: name)),
			.parentCategoryID: parent.encoded,
		]
	}
}
