//
//  SwlCard+SQLiteQueryReadWritable.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.Card: SQLiteQueryReadWritable {
	/*
	 CREATE TABLE IF NOT EXISTS "spbwlt_Card" (^M
	 "ID" VARCHAR(22)  UNIQUE NOT NULL PRIMARY KEY,^M
	 "Name" BLOB  NOT NULL,^M
	 "Description" BLOB NULL,^M
	 "CardViewID" VARCHAR(22)  NOT NULL,^M
	 "HasOwnCardView" INTEGER NOT NULL DEFAULT 0,^M
	 "TemplateID" VARCHAR(22)  NOT NULL,^M
	 "ParentCategoryID" VARCHAR(22)  NOT NULL,^M
	 "IconID" VARCHAR(22)  NOT NULL,^M
	 "HitCount" INTEGER DEFAULT 0  NOT NULL,^M
	 "SyncID" INTEGER NOT NULL DEFAULT -1, ^M
	 "CreateSyncID" INTEGER NOT NULL DEFAULT -1^M
	 );
	 */

	enum Column: String, CaseIterable {
		case id
		case name
		/// The free-text which the original client rendered below the fields. Seeming to be better described as a bucket for free-form encrypted content rather than as a subtitle.
		case description
		case cardViewID
		case hasOwnCardView
		case templateID
		case parentCategoryID
		case iconID
		case hitCount
		case syncID
		case createSyncID
	}

	static let columns: [Column] = Column.allCases
	static let table = SwlDatabase.Tables.cards
	static let primary: Column = .id
	func encode() -> [Column: SQLiteDataType] {
		[
			.id: id.encoded,
			.name: .blob(value: .init(arrayValue: name)),
			.description: .nullableBlob(value: (description == nil) ? nil : .init(arrayValue: description!)),
			.cardViewID: cardViewID.encoded,
			.hasOwnCardView: .integer(value: hasOwnCardView),
			.templateID: templateID.encoded,
			.parentCategoryID: parent.encoded,
			.iconID: iconID.encoded,
			.hitCount: .integer(value: hitCount),
			.syncID: .integer(value: syncID),
			.createSyncID: .integer(value: createSyncID),
		]
	}
}
