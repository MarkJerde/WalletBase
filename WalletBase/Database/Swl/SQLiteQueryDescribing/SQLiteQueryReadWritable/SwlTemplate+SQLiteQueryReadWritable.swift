//
//  SwlTemplate+SQLiteQueryReadWritable.swift
//  WalletBase
//
//  Created by Mark Jerde on 2/23/23.
//

import Foundation

extension SwlDatabase.Template: SQLiteQueryReadWritable {
	/*
	 CREATE TABLE IF NOT EXISTS "spbwlt_Template" (^M
	 "ID" VARCHAR(22)  UNIQUE NOT NULL PRIMARY KEY,^M
	 "Name" BLOB  NOT NULL,^M
	 "Description" BLOB NULL,^M
	 "CardViewID" VARCHAR(22)  NOT NULL,^M
	 "SyncID" INTEGER NOT NULL DEFAULT -1,^M
	 "CreateSyncID" INTEGER NOT NULL DEFAULT -1^M
	 );
	 */

	enum Column: String, CaseIterable {
		case id
		case name
		case description
		case cardViewID
		case syncID
		case createSyncID
	}

	static let columns: [Column] = Column.allCases
	static let table = SwlDatabase.Tables.templates
	static let primary: Column = .id
	func encode() -> [Column: SQLiteDataType] {
		[
			.id: id.encoded,
			.name: .blob(value: .init(arrayValue: name)),
			.description: .nullableBlob(value: (description == nil) ? nil : .init(arrayValue: description!)),
			.cardViewID: cardViewID.encoded,
			.syncID: .integer(value: syncID),
			.createSyncID: .integer(value: createSyncID),
		]
	}
}
