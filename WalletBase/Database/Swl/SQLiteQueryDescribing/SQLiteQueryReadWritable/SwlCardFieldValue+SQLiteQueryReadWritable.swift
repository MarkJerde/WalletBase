//
//  SwlCardFieldValue+SQLiteQueryReadWritable.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.CardFieldValue: SQLiteQueryReadWritable {
	/*
	 CREATE TABLE IF NOT EXISTS "spbwlt_CardFieldValue" (^M
	 "ID" VARCHAR(22)  UNIQUE NOT NULL PRIMARY KEY,^M
	 "CardID" VARCHAR(22)  NOT NULL,^M
	 "TemplateFieldID" VARCHAR(22)  NOT NULL,^M
	 "ValueString" BLOB NULL,^M
	 "SyncID" INTEGER NOT NULL DEFAULT -1,^M
	 "CreateSyncID" INTEGER NOT NULL DEFAULT -1^M
	 );
	 */

	enum Column: String, CaseIterable {
		case id
		case cardID
		case templateFieldID
		case valueString
		case syncID
		case createSyncID
	}

	static let columns: [Column] = Column.allCases
	static let table = SwlDatabase.Tables.cardFieldValues
	static let primary: Column = .id
	func encode() -> [Column: SQLiteDataType] {
		[
			.id: id.encoded,
			.cardID: cardId.encoded,
			.templateFieldID: templateFieldId.encoded,
			.valueString: .nullableBlob(value: .init(arrayValue: value)),
			.syncID: .integer(value: -1), // (default: -1)
			.createSyncID: .integer(value: -1), // (default: -1)
		]
	}
}
