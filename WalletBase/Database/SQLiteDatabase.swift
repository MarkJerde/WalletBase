//
//  SQLiteDatabase.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/18/21.
//

import Foundation
import SQLite3

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
	static var columns: [String] { get }
	static var table: SQLiteTable { get }
}

/// A wrapper around an SQLite database session.
class SQLiteDatabase {
	/// The database file.
	let file: URL

	private var database: OpaquePointer? {
		if let database = _database { return database }

		var database: OpaquePointer?
		guard sqlite3_open(file.path, &database) == SQLITE_OK else {
			sqlite3_close(database)
			database = nil
			return nil
		}

		_database = database
		return _database
	}

	private var _database: OpaquePointer?

	/// Creates and returns an SQLite database session wrapper for the specified database file.
	/// - Parameter file: The database file.
	init(file: URL) {
		self.file = file
	}

	/// An error that occurs during the execution of database commands.
	struct DatabaseError: Error {
		/// The database command that was being called.
		let site: Site
		/// The problem that occurred.
		let problem: Problem

		init(site: Site, database: OpaquePointer?) {
			self.site = site
			guard let errmsgCString = sqlite3_errmsg(database) else {
				problem = .failedWithoutError
				return
			}
			let errmsg = String(cString: errmsgCString)
			problem = .error(errmsg)
		}

		enum Site {
			case prepare
			case finalize
		}

		enum Problem {
			case failedWithoutError
			case error(String)
		}
	}

	/// Performs a select operation on the database, selecting for the table and columns of the return type with the given where clause (if any).
	///   - where: The where clause to filter by. (No filtering if nil.)
	/// - Returns: An array containing the selected items from the database.
	func select<T: SQLiteDatabaseItem>(where whereClause: String? = nil) throws -> [T?] where T: SQLiteQueryDescribing {
		try select(columns: T.columns, fromTable: T.table, where: whereClause)
	}

	/// Performs a select operation on the database, selecting the named columns from the named table with the given where clause (if any).
	/// - Parameters:
	///   - columns: The columns to select.
	///   - fromTable: The table to select from.
	///   - where: The where clause to filter by. (No filtering if nil.)
	/// - Returns: An array containing the selected items from the database.
	func select<T: SQLiteDatabaseItem>(columns: [String], fromTable table: SQLiteTable, where whereClause: String? = nil) throws -> [T?] {
		var statement: OpaquePointer?

		let statementText = "select \(columns.joined(separator: ", ")) from \(table.name) \((whereClause != nil) ? "where" : "") \(whereClause ?? "")"
		guard sqlite3_prepare_v2(database, statementText, -1, &statement, nil) == SQLITE_OK,
		      let statement = statement
		else {
			throw DatabaseError(site: .prepare, database: database)
		}

		var response: [T?] = []
		while sqlite3_step(statement) == SQLITE_ROW {
			response.append(T.decode(from: statement, column: 0, nextColumn: nil))
		}

		guard sqlite3_finalize(statement) == SQLITE_OK else {
			throw DatabaseError(site: .finalize, database: database)
		}

		return response
	}
}
