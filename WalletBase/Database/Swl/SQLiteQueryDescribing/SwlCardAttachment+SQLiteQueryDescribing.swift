//
//  SwlCardAttachment+SQLiteQueryDescribing.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.CardAttachment: SQLiteQueryDescribing {
	static let columns = ["ID", "CardID", "Name", "Data"]
	static let table: SQLiteTable = SwlDatabase.Tables.cardAttachments
}
