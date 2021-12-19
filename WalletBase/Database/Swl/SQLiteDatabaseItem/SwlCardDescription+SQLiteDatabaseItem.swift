//
//  SwlCardDescription+SQLiteDatabaseItem.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/18/21.
//

import Foundation
import SQLite3

extension SwlDatabase.CardDescription: SQLiteDatabaseItem {
	/// Creates a new instance by decoding from the given statement.
	/// - Parameters:
	///   - statement: The statement to decode from.
	///   - column: The column at which to start decoding. Multiple columns may be consumed if it is a composite type.
	/// - Returns: The decoded instance.
	static func decode(from statement: OpaquePointer, column: Int32 = 0) -> Self? {
		// Decode the parts.
		guard let id: SwlDatabase.SwlID = .decode(from: statement, column: column) else { return nil }
		let description: [UInt8]? = .decode(from: statement, column: column + 1)

		// Build and return the instance.
		return .init(id: id, description: description)
	}
}
