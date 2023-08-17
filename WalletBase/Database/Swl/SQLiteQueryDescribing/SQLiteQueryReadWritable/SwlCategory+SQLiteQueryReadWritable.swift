//
//  SwlCategory+SQLiteQuerySelectable.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.Category: SQLiteQueryReadWritable {
	/*
		CREATE TABLE IF NOT EXISTS "spbwlt_Category" (^M
		"ID" VARCHAR(22) UNIQUE NOT NULL PRIMARY KEY,^M
		"Name" BLOB NOT NULL,^M
		"Description" BLOB NULL,^M
		"IconID" VARCHAR(22)  NOT NULL,^M
		"DefaultTemplateID" VARCHAR(22),^M
		"ParentCategoryID" VARCHAR(22)  NOT NULL,^M
		"SyncID" INTEGER NOT NULL DEFAULT -1,^M
		"CreateSyncID" INTEGER NOT NULL DEFAULT -1^M
		);
		*/

	enum Column: String, CaseIterable {
		case id
		case name
		case description
		case iconID
		case defaultTemplateID
		case parentCategoryID
		case syncID
		case createSyncID
	}

	static let columns: [Column] = Column.allCases
	static let table = SwlDatabase.Tables.categories
	static let primary: Column = .id
	func encode() -> [Column: SQLiteDataType] {
		[
			.id: id.encoded,
			.name: .blob(value: .init(arrayValue: name)),
			.description: .nullableBlob(value: (description == nil) ? nil : .init(arrayValue: description!)),
			.iconID: iconID.encoded,
			.defaultTemplateID: defaultTemplateID.encoded,
			.parentCategoryID: parent.encoded,
			.syncID: .integer(value: syncID),
			.createSyncID: .integer(value: createSyncID),
		]
	}
}
