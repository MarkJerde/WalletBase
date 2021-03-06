//
//  SwlID+SQLiteDatabaseItem.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/26/21.
//

import Foundation
import SQLite3

extension SwlDatabase.SwlID: SQLiteDatabaseItem {
	/// Creates a new instance by decoding from the given statement.
	/// - Parameters:
	///   - statement: The statement to decode from.
	///   - column: The column at which to start decoding. Multiple columns may be consumed if it is a composite type.
	/// - Returns: The decoded instance.
	static func decode(from statement: OpaquePointer, column: Int32 = 0, nextColumn: ((Int32) -> Void)?) -> Self? {
		guard let cString = sqlite3_column_text(statement, column) else {
			return nil
		}

		let length = sqlite3_column_bytes(statement, column)
		let buffer = UnsafeBufferPointer(start: cString, count: Int(length))

		let array = Array(buffer)

		nextColumn?(column + 1)

		return Self(value: array)
	}
}
