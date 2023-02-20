//
//  Array+SQLiteDatabaseItem.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/26/21.
//

import Foundation
import SQLite3

extension Array: SQLiteDatabaseItem where Element == UInt8 {
	/// Creates a new instance by decoding from the given statement.
	/// - Parameters:
	///   - statement: The statement to decode from.
	///   - column: The column at which to start decoding. Multiple columns may be consumed if it is a composite type.
	/// - Returns: The decoded instance.
	static func decode(from statement: OpaquePointer, column: Int32 = 0, nextColumn: ((Int32) -> Void)?) -> Self? {
		let length = sqlite3_column_bytes(statement, column)
		let pointer = sqlite3_column_blob(statement, column)

		defer {
			nextColumn?(column + 1)
		}

		guard pointer != nil else {
			return nil
		}

		let data = NSData(bytes: pointer, length: Int(length))
		let array = [UInt8](data)

		return array
	}
}
