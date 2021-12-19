//
//  SwlCardDescription+SQLiteQueryDescribing.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.CardDescription: SQLiteQueryDescribing {
	static let columns = ["ID", "Description"]
	static let table: SQLiteTable = SwlDatabase.Tables.cards
}
