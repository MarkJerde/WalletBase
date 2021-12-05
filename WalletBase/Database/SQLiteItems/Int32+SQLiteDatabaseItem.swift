//
//  Int32+SQLiteDatabaseItem.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/4/21.
//

import Foundation
import SQLite3

extension Int32: SQLiteDatabaseItem {
	/// Creates a new instance by decoding from the given statement.
	/// - Parameters:
	///   - statement: The statement to decode from.
	///   - column: The column at which to start decoding. Multiple columns may be consumed if it is a composite type.
	/// - Returns: The decoded instance.
	static func decode(from statement: OpaquePointer, column: Int32 = 0) -> Self? {
		sqlite3_column_int(statement, column)
	}
}
