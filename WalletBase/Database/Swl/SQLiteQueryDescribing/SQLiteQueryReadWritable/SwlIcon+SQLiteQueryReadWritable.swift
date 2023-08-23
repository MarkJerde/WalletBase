//
//  SwlIcon+SQLiteQueryReadWritable.swift
//  WalletBase
//
//  Created by Mark Jerde on 8/22/23.
//

import Foundation

extension SwlDatabase.Icon: SQLiteQueryReadWritable {
	/*
	 "ID" VARCHAR(22)  UNIQUE NOT NULL PRIMARY KEY,
	 "Name" BLOB  NOT NULL,
	 "Data" BLOB ,
	 "SyncID" INTEGER NOT NULL DEFAULT -1,
	 "CreateSyncID" INTEGER NOT NULL DEFAULT -1
	 */

	enum Column: String, CaseIterable {
		case id
		case name
		case data
		case syncID
		case createSyncID
	}

	static let columns: [Column] = Column.allCases
	static let table = SwlDatabase.Tables.icon
	static let primary: Column = .id
	func encode() -> [Column: SQLiteDataType] {
		[
			.id: id.encoded,
			.name: .blob(value: .init(arrayValue: name)),
			.data: .nullableBlob(value: (data == nil) ? nil : .init(arrayValue: data!)),
			.syncID: .integer(value: syncID),
			.createSyncID: .integer(value: createSyncID),
		]
	}
}
