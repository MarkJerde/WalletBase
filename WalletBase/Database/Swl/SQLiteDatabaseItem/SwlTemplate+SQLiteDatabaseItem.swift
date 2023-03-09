//
//  SwlTemplate+SQLiteDatabaseItem.swift
//  WalletBase
//
//  Created by Mark Jerde on 2/23/23.
//

import Foundation
import SQLite3

extension SwlDatabase.Template: SQLiteDatabaseItem {
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
		guard let id: SwlDatabase.SwlID = .decode(from: statement, column: column, nextColumn: { column = $0 }),
		      let name: [UInt8] = .decode(from: statement, column: column, nextColumn: { column = $0 }) else { return nil }
		let description: [UInt8]? = .decode(from: statement, column: column, nextColumn: { column = $0 })
		guard let cardViewId: SwlDatabase.SwlID = .decode(from: statement, column: column, nextColumn: { column = $0 }),
		      let syncID: Int32 = .decode(from: statement, column: column, nextColumn: { column = $0 }),
		      let createSyncID: Int32 = .decode(from: statement, column: column, nextColumn: { column = $0 }) else { return nil }

		// Build and return the instance.
		return .init(id: id,
		             name: name,
		             description: description,
		             cardViewID: cardViewId,
		             syncID: syncID,
		             createSyncID: createSyncID)
	}
}
