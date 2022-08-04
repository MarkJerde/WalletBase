//
//  SQLiteProtocols.swift
//  WalletBase
//
//  Created by Mark Jerde on 8/2/22.
//

import Foundation

/// A type that can be decoded from an SQLite statement beginning at a given column.
protocol SQLiteDatabaseItem {
	/// Creates a new instance by decoding from the given statement.
	/// - Parameters:
	///   - statement: The statement to decode from.
	///   - column: The column at which to start decoding. Multiple columns may be consumed if it is a composite type.
	///   - nextColumn: A closure to which is passed the next column number, to provide incrementing.
	/// - Returns: The decoded instance.
	static func decode(from statement: OpaquePointer, column: Int32, nextColumn: ((Int32) -> Void)?) -> Self?
}

protocol SQLiteTable {
	var name: String { get }
}

protocol SQLiteQueryDescribing {
	static var columns: [Column] { get }
	static var table: Table { get }
	associatedtype Table: SQLiteTable
	associatedtype Column: Hashable & RawRepresentable where Column.RawValue == String
}
