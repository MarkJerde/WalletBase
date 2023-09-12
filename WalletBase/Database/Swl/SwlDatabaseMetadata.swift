//
//  SwlDatabaseMetadata.swift
//  WalletBase
//
//  Created by Mark Jerde on 9/10/23.
//

import Foundation

// NOTE: I broke with the trend here by placing both extensions in the same file with the struct because I didn't feel like creating the extra files. I'm not sure that this is a bad thing.
// The groups structure was helpful when growing types to have more features, but this one needed all of the features from the start and is under 100 lines.
// Splitting into too many small files increases the effort necessary to work with the code. Perhaps the others should move in this direction, or perhaps they are too large. Perhaps this one should move to match the others. For now, this is a trial balloon to help inform the best path forward for the code as a whole.

extension SwlDatabase {
	/// The swl database metadata record.
	struct DatabaseMetadata {
		/// The number of PKDF2 rounds to use.
		let rounds: Int32
		/// The PKDF2 salt to use.
		let salt: [UInt8]
	}
}

import SQLite3

extension SwlDatabase.DatabaseMetadata: SQLiteDatabaseItem {
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
		guard let rounds: Int32 = .decode(from: statement, column: column, nextColumn: { column = $0 }),
		      let salt: [UInt8] = .decode(from: statement, column: column, nextColumn: { column = $0 }) else { return nil }

		// Build and return the instance.
		return .init(rounds: rounds,
		             salt: salt)
	}
}

extension SwlDatabase.DatabaseMetadata: SQLiteQueryReadWritable {
	/*
	 CREATE TABLE IF NOT EXISTS "spbwlt_DatabaseMetadata" (
	 "Rounds" INTEGER  NOT NULL PRIMARY KEY,
	 "Salt" BLOB NOT NULL,
	 );
	 */

	enum Column: String, CaseIterable {
		case rounds
		case salt
	}

	static let columns: [Column] = Column.allCases
	static let table = SwlDatabase.Tables.databaseMetadata
	static let primary: Column = .rounds
	func encode() -> [Column: SQLiteDataType] {
		[
			.rounds: .integer(value: rounds),
			.salt: .blob(value: .init(arrayValue: salt)),
		]
	}
}
