//
//  SwlTemplateFieldType+SQLiteQueryReadWritable.swift
//  WalletBase
//
//  Created by Mark Jerde on 8/22/23.
//

import Foundation

extension SwlDatabase.TemplateFieldType: SQLiteQueryReadWritable {
	/*
	 "ID" INTEGER  PRIMARY KEY NOT NULL,
	 "Name" NVARCHAR(256)  NOT NULL,
	 "SyncID" INTEGER NOT NULL DEFAULT -1,
	 "CreateSyncID" INTEGER NOT NULL DEFAULT -1
	 */

	enum Column: String, CaseIterable {
		case id
		case name
		case syncID
		case createSyncID
	}

	static let columns: [Column] = Column.allCases
	static let table = SwlDatabase.Tables.templateFieldTypes
	static let primary: Column = .id
	func encode() -> [Column: SQLiteDataType] {
		[
			.id: .integer(value: id),
			.name: .varchar(value: .init(stringValue: name)),
			.syncID: .integer(value: -1), // (default: -1)
			.createSyncID: .integer(value: -1), // (default: -1)
		]
	}
}
