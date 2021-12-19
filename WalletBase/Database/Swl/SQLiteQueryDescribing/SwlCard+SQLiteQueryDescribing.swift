//
//  SwlCard+SQLiteQueryDescribing.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.Card: SQLiteQueryDescribing {
	static let columns = ["ID", "Name", "ParentCategoryID"]
	static let table: SQLiteTable = SwlDatabase.Tables.cards
}
