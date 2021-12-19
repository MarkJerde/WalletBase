//
//  SwlCardFieldValue+SQLiteQueryDescribing.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.CardFieldValue: SQLiteQueryDescribing {
	static let columns = ["ID", "CardID", "TemplateFieldID", "ValueString"]
	static let table: SQLiteTable = SwlDatabase.Tables.cardFieldValues
}
