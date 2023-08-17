//
//  SwlCardAttachment+SQLiteQueryReadWritable.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.CardAttachment: SQLiteQueryReadWritable {
	/*
	 CREATE TABLE IF NOT EXISTS "spbwlt_CardAttachment" (
	 "ID" VARCHAR(22)  UNIQUE NOT NULL PRIMARY KEY,
	 "CardID" VARCHAR(22)  NOT NULL,
	 "Name" BLOB  NOT NULL,
	 "Data" BLOB,
	 "SyncID" INTEGER NOT NULL DEFAULT -1,
	 "CreateSyncID" INTEGER NOT NULL DEFAULT -1
	 );
	 */

	enum Column: String, CaseIterable {
		case id
		case cardID
		case name
		case data
		case syncID
		case createSyncID
	}

	static let columns: [Column] = Column.allCases
	static let table = SwlDatabase.Tables.cardAttachments
	static let primary: Column = .id
	func encode() -> [Column: SQLiteDataType] {
		[
			.id: id.encoded,
			.cardID: cardId.encoded,
			.name: .blob(value: .init(arrayValue: name)),
			.data: .nullableBlob(value: .init(arrayValue: data)),
			.syncID: .integer(value: syncID),
			.createSyncID: .integer(value: createSyncID),
		]
	}
}
