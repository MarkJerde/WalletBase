//
//  SwlCardAttachment+SQLiteQuerySelectable.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.CardAttachment: SQLiteQuerySelectable {
	enum Column: String {
		case id
		case cardID
		case name
		case data
	}

	static let columns: [Column] = [.id, .cardID, .name, .data]
	static let table = SwlDatabase.Tables.cardAttachments
}
