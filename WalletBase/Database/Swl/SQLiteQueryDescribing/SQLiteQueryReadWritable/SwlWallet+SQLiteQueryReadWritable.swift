//
//  SwlWallet+SQLiteQueryReadWritable.swift
//  WalletBase
//
//  Created by Mark Jerde on 8/9/23.
//

import Foundation

extension SwlDatabase.Wallet: SQLiteQueryReadWritable {
	/*
	 CREATE TABLE IF NOT EXISTS "spbwlt_Wallet" (^M
	 "ID" VARCHAR(22)  UNIQUE NOT NULL PRIMARY KEY,^M
	 "AdvVersionInfo" INTEGER  NOT NULL,^M
	 "CurrentSyncID" INTEGER NOT NULL DEFAULT -1,^M
	 "SyncID" INTEGER DEFAULT -1,^M
	 "SyncInfo" BLOB,^M
	 "CreateSyncID" INTEGER NOT NULL DEFAULT -1^M
	 );
	 */

	enum Column: String, CaseIterable {
		case id
		case advVersionInfo
		case currentSyncID
		case syncID
		case syncInfo
		case createSyncID
	}

	static let columns: [Column] = Column.allCases
	static let table = SwlDatabase.Tables.wallet
	static let primary: Column = .id
	func encode() -> [Column: SQLiteDataType] {
		[
			.id: id.encoded,
			.advVersionInfo: .integer(value: advVersionInfo),
			.currentSyncID: .integer(value: currentSyncID), // (default: -1)
			.syncID: .integer(value: syncID), // (default: -1)
			.syncInfo: .nullableBlob(value: (syncInfo == nil) ? nil : .init(arrayValue: syncInfo!)),
			.createSyncID: .integer(value: createSyncID), // (default: -1)
		]
	}
}
