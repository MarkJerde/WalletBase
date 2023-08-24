//
//  SwlDatabaseVersion+SQLiteDatabaseItem.swift
//  WalletBase
//
//  Created by Mark Jerde on 8/23/23.
//

import Foundation
import SQLite3

extension SwlDatabase.DatabaseVersion: SQLiteDatabaseItem {
	/// Creates a new instance by decoding from the given statement.
	/// - Parameters:
	///   - statement: The statement to decode from.
	///   - column: The column at which to start decoding. Multiple columns may be consumed if it is a composite type.
	/// - Returns: The decoded instance.
	static func decode(from statement: OpaquePointer, column: Int32 = 0, nextColumn: ((Int32) -> Void)?) -> Self? {
		defer {
			nextColumn?(column)
		}

		// Decode the parts.
		var column = column
		guard let productID: Int32 = .decode(from: statement, column: column, nextColumn: { column = $0 }),
		      let productName: String = .decode(from: statement, column: column, nextColumn: { column = $0 }),
		      let versionString: String = .decode(from: statement, column: column, nextColumn: { column = $0 }),
		      let compatibilityVersion: Int32 = .decode(from: statement, column: column, nextColumn: { column = $0 }),
		      let productMajorVersion: Int32 = .decode(from: statement, column: column, nextColumn: { column = $0 }),
		      let productMinorVersion: Int32 = .decode(from: statement, column: column, nextColumn: { column = $0 }) else { return nil }

		// Build and return the instance.
		return .init(productID: productID,
		             productName: productName,
		             versionString: versionString,
		             compatibilityVersion: compatibilityVersion,
		             productMajorVersion: productMajorVersion,
		             productMinorVersion: productMinorVersion)
	}
}
