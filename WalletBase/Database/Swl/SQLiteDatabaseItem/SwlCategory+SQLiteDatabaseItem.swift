//
//  SwlCategory+SQLiteDatabaseItem.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/26/21.
//

import Foundation
import SQLite3

extension SwlDatabase.Category: SQLiteDatabaseItem {
	/// Creates a new instance by decoding from the given statement.
	/// - Parameters:
	///   - statement: The statement to decode from.
	///   - column: The column at which to start decoding. Multiple columns may be consumed if it is a composite type.
	/// - Returns: The decoded instance.
	static func decode(from statement: OpaquePointer, column: Int32 = 0, nextColumn: ((Int32) -> Void)?) -> Self? {
		// Decode the parts.
		defer {
			nextColumn?(column)
		}

		var column = column
		guard let id: SwlDatabase.SwlID = .decode(from: statement, column: column, nextColumn: { column = $0 }) else { return nil }
		guard let name: [UInt8] = .decode(from: statement, column: column, nextColumn: { column = $0 }) else { return nil }
		let description: [UInt8]? = .decode(from: statement, column: column, nextColumn: { column = $0 })
		guard let iconID: SwlDatabase.SwlID = .decode(from: statement, column: column, nextColumn: { column = $0 }) else { return nil }
		guard let defaultTemplateID: SwlDatabase.SwlID = .decode(from: statement, column: column, nextColumn: { column = $0 }) else { return nil }
		guard let parent: SwlDatabase.SwlID = .decode(from: statement, column: column, nextColumn: { column = $0 }),
		      let syncID: Int32 = .decode(from: statement, column: column, nextColumn: { column = $0 }),
		      let createSyncID: Int32 = .decode(from: statement, column: column, nextColumn: { column = $0 }) else { return nil }

		// Build and return the instance.
		return .init(id: id,
		             name: name,
		             description: description,
		             iconID: iconID,
		             defaultTemplateID: defaultTemplateID,
		             parent: parent,
		             syncID: syncID,
		             createSyncID: createSyncID)
	}
}
