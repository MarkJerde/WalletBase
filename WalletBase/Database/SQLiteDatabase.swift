//
//  SQLiteDatabase.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/18/21.
//

import Foundation
import SQLite3

class SQLiteDatabase {
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

	init(file: URL) {
		self.file = file
	}

	struct DatabaseError: Error {
		let site: Site
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

	func select(columns: [String], fromTable table: String, where whereClause: String? = nil) throws -> [[UInt8]?] {
		var statement: OpaquePointer?

		guard sqlite3_prepare_v2(database, "select \(columns.joined(separator: ", ")) from \(table) \((whereClause != nil) ? "where" : "") \(whereClause ?? "")", -1, &statement, nil) == SQLITE_OK else {
			throw DatabaseError(site: .prepare, database: database)
		}

		var response: [[UInt8]?] = []
		while sqlite3_step(statement) == SQLITE_ROW {
			let length = sqlite3_column_bytes(statement, 0)
			let pointer = sqlite3_column_blob(statement, 0)
			guard pointer != nil else {
				response.append(nil)
				continue
			}
			let data = NSData(bytes: pointer, length: Int(length))
			let array = [UInt8](data)
			response.append(array)
			/* guard let cString = sqlite3_column_text(statement, 0) else {
			 	response.append(nil)
			 	continue
			 }
			 	let value = String(cString: cString)
			 response.append(value) */
		}

		guard sqlite3_finalize(statement) == SQLITE_OK else {
			throw DatabaseError(site: .finalize, database: database)
		}

		return response
	}
}