//
//  SwlTemplateField+SQLiteQueryReadWritable.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.TemplateField: SQLiteQueryReadWritable {
	/*
	 CREATE TABLE IF NOT EXISTS "spbwlt_TemplateField" (^M
	 "ID" VARCHAR(22)  UNIQUE NOT NULL PRIMARY KEY,^M
	 "Name" BLOB NOT NULL,^M
	 "TemplateID" VARCHAR(22)  NOT NULL,^M
	 "FieldTypeID" INTEGER  NOT NULL,^M
	 "Priority"  INTEGER DEFAULT "0" NOT NULL,^M
	 "SyncID" INTEGER NOT NULL DEFAULT -1,^M
	 "AdvInfo" BLOB,^M
	 "CreateSyncID" INTEGER NOT NULL DEFAULT -1^M
	 );
	 */

	enum Column: String, CaseIterable {
		case id
		case name
		case templateID
		case fieldTypeID
		case priority
		case syncID
		case advInfo
		case createSyncID
	}

	static let columns: [Column] = Column.allCases
	static let table = SwlDatabase.Tables.templateFields
	static let primary: Column = .id
	func encode() -> [Column: SQLiteDataType] {
		[
			.id: id.encoded,
			.name: .blob(value: .init(arrayValue: name)),
			.templateID: templateId.encoded,
			.fieldTypeID: .integer(value: fieldTypeId),
			.priority: .integer(value: priority),
			.syncID: .integer(value: -1), // (default: -1)
			.advInfo: .nullableBlob(value: nil),
			.createSyncID: .integer(value: -1), // (default: -1)
		]
	}
}
