//
//  SwlCardDescription+SQLiteQuerySelectable.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.CardDescription: SQLiteQuerySelectable {
	enum Column: String {
		case id
		case description
	}

	static let columns: [Column] = [.id, .description]
	static let table = SwlDatabase.Tables.cards
}
