//
//  SwlDatabaseVersion+SQLiteQueryReadWritable.swift
//  WalletBase
//
//  Created by Mark Jerde on 8/23/23.
//

import Foundation

extension SwlDatabase.DatabaseVersion: SQLiteQueryReadWritable {
	/*
	 "ProductID" INTEGER  NOT NULL PRIMARY KEY,
	 "ProductName" VARCHAR(256)  NOT NULL,
	 "VersionString" VARCHAR(256)  NOT NULL,
	 "CompatibilityVersion" INTEGER  NOT NULL,
	 "ProductMajorVersion" INTEGER  NOT NULL,
	 "ProductMinorVersion" INTEGER  NOT NULL
	 */

	enum Column: String, CaseIterable {
		case productID
		case productName
		case versionString
		case compatibilityVersion
		case productMajorVersion
		case productMinorVersion
	}

	static let columns: [Column] = Column.allCases
	static let table = SwlDatabase.Tables.databaseVersion
	static let primary: Column = .productID
	func encode() -> [Column: SQLiteDataType] {
		[
			.productID: .integer(value: productID),
			.productName: .varchar(value: .init(stringValue: productName)),
			.versionString: .varchar(value: .init(stringValue: versionString)),
			.compatibilityVersion: .integer(value: compatibilityVersion),
			.productMajorVersion: .integer(value: productMajorVersion),
			.productMinorVersion: .integer(value: productMinorVersion),
		]
	}
}
