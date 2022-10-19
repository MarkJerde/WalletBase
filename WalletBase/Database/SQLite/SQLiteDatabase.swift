//
//  SQLiteDatabase.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/18/21.
//

import Foundation
import SQLite3

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

	private func close() -> Bool {
		guard let database = _database else {
			return true
		}
		_database = nil
		return sqlite3_close(database) == SQLITE_OK
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
			case step
			case finalize
			case exec
		}

		enum Problem {
			case failedWithoutError
			case error(String)
		}
	}

	/// An error that occurs in this layer between a call site and the database.
	struct LayerError: Error {
		/// The site of the problem.
		let site: Site
		/// The problem that occurred.
		let problem: Problem

		enum Site {
			case insert
			case update
			case backup
			case beginTransaction
			case commitTransaction
			case rollbackTransaction
		}

		enum Problem {
			case generalError
			case requirements
		}
	}

	private var transactionInProgress = false

	func beginTransaction() throws {
		guard !transactionInProgress else {
			throw LayerError(site: .beginTransaction, problem: .requirements)
		}

		guard sqlite3_exec(database, "BEGIN TRANSACTION;", nil, nil, nil) == SQLITE_OK
		else {
			throw DatabaseError(site: .exec, database: database)
		}

		transactionInProgress = true
	}

	func commitTransaction() throws {
		guard transactionInProgress else {
			throw LayerError(site: .commitTransaction, problem: .requirements)
		}

		guard sqlite3_exec(database, "COMMIT TRANSACTION;", nil, nil, nil) == SQLITE_OK
		else {
			throw DatabaseError(site: .exec, database: database)
		}

		transactionInProgress = false
	}

	func rollbackTransaction() throws {
		guard transactionInProgress else {
			throw LayerError(site: .rollbackTransaction, problem: .requirements)
		}

		transactionInProgress = false

		guard sqlite3_exec(database, "ROLLBACK TRANSACTION;", nil, nil, nil) == SQLITE_OK
		else {
			throw DatabaseError(site: .exec, database: database)
		}
	}

	/// Performs a select operation on the database, selecting for the table and columns of the return type with the given where clause (if any).
	///   - where: The where clause to filter by. (No filtering if nil.)
	/// - Returns: An array containing the selected items from the database.
	func select<T: SQLiteDatabaseItem>(where whereClause: String? = nil) throws -> [T?] where T: SQLiteQuerySelectable {
		try select(columns: T.columns.map { $0.rawValue }, fromTable: T.table, where: whereClause)
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

	func insert<T: SQLiteDatabaseItem>(record: T) throws where T: SQLiteQueryWritable {
		try insert(into: T.table, values: record.insertionValues())
	}

	func insert<Table>(into table: Table, values: [SQLiteDataType]) throws where Table: SQLiteTable {
		guard canBackupDatabaseFile,
		      backupDatabaseFile()
		else {
			throw LayerError(site: .backup, problem: .generalError)
		}

		var statement: OpaquePointer?

		let statementText = "insert into \(table.name) values (\(values.map { $0.queryValue }.joined(separator: ", ")))"
		guard sqlite3_prepare_v2(database, statementText, -1, &statement, nil) == SQLITE_OK,
		      let statement = statement
		else {
			throw DatabaseError(site: .prepare, database: database)
		}

		guard sqlite3_finalize(statement) == SQLITE_OK else {
			throw DatabaseError(site: .finalize, database: database)
		}
	}

	func update<T: SQLiteDatabaseItem>(record: T, from previousRecord: T? = nil) throws where T: SQLiteQueryWritable {
		var recordValues = record.encode()
		if let previousRecord = previousRecord {
			let previousValues = previousRecord.encode()
			for key in previousValues.keys {
				guard key != T.primary,
				      recordValues[key] == previousValues[key] else { continue }
				recordValues.removeValue(forKey: key)
			}
		}
		try update(from: T.table, values: recordValues, primary: T.primary)
	}

	func update<Table, Column>(from table: Table, values: [Column: SQLiteDataType], primary: Column) throws where Table: SQLiteTable, Column: Hashable & RawRepresentable, Column.RawValue == String {
		guard canBackupDatabaseFile,
		      backupDatabaseFile()
		else {
			throw LayerError(site: .backup, problem: .generalError)
		}

		guard let primaryValue = values[primary] else {
			throw LayerError(site: .update, problem: .requirements)
		}

		var values = values
		values.removeValue(forKey: primary)

		var statement: OpaquePointer?

		let statementText = "update \(table.name) set \(values.map { "\($0.key.rawValue) = \($0.value.queryValue)" }.joined(separator: ", ")) where \(primary) == \(primaryValue.queryValue)"
		guard sqlite3_prepare_v2(database, statementText, -1, &statement, nil) == SQLITE_OK,
		      let statement = statement
		else {
			throw DatabaseError(site: .prepare, database: database)
		}

		guard sqlite3_step(statement) == SQLITE_DONE else {
			throw DatabaseError(site: .step, database: database)
		}

		guard sqlite3_finalize(statement) == SQLITE_OK else {
			throw DatabaseError(site: .finalize, database: database)
		}
	}

	var canBackupDatabaseFile: Bool {
		FileStorage.contains(file)
	}

	func backupDatabaseFile() -> Bool {
		guard close() else { return false }
		return FileStorage.backupFile(at: file) != nil
	}
}
