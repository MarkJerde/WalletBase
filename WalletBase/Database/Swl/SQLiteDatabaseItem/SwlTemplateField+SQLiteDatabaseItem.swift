//
//  SwlTemplateField+SQLiteDatabaseItem.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/4/21.
//

import Foundation
import SQLite3

extension SwlDatabase.TemplateField: SQLiteDatabaseItem {
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
		guard let id: SwlDatabase.SwlID = .decode(from: statement, column: column, nextColumn: { column = $0 }) else { return nil }
		guard let name: [UInt8] = .decode(from: statement, column: column, nextColumn: { column = $0 }) else { return nil }
		guard let templateId: SwlDatabase.SwlID = .decode(from: statement, column: column, nextColumn: { column = $0 }) else { return nil }
		guard let fieldTypeId: Int32 = .decode(from: statement, column: column, nextColumn: { column = $0 }) else { return nil }
		guard let priority: Int32 = .decode(from: statement, column: column, nextColumn: { column = $0 }) else { return nil }
		let advancedInfo: [UInt8]? = .decode(from: statement, column: column, nextColumn: { column = $0 })

		// Build and return the instance.
		return .init(id: id,
		             name: name,
		             templateId: templateId,
		             fieldTypeId: fieldTypeId,
		             priority: priority,
		             advancedInfo: advancedInfo)
	}
}
