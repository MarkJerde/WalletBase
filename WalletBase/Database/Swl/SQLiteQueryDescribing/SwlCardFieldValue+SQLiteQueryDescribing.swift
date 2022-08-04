//
//  SwlCardFieldValue+SQLiteQueryDescribing.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.CardFieldValue: SQLiteQueryDescribing {
	enum Column: String {
		case id
		case cardID
		case templateFieldID
		case valueString
	}

	static let columns: [Column] = [.id, .cardID, .templateFieldID, .valueString]
	static let table = SwlDatabase.Tables.cardFieldValues
}
