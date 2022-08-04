//
//  SwlCard+SQLiteQueryDescribing.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.Card: SQLiteQueryDescribing {
	enum Column: String {
		case id
		case name
		case parentCategoryID
	}

	static let columns: [Column] = [.id, .name, .parentCategoryID]
	static let table = SwlDatabase.Tables.cards
}
