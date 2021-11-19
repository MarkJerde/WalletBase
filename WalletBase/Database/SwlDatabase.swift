//
//  SwlDatabase.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/10/21.
//

import Foundation

class SwlDatabase {
	let database: SQLiteDatabase
	var file: URL { database.file }

	init(file: URL) {
		self.database = SQLiteDatabase(file: file)
	}

	func open(password: (@escaping (String) -> Void) -> Void, completion: @escaping (Bool) -> Void) {
		let crypto = SwlCrypto()
		self.crypto = crypto
		crypto.unlock(password: password, completion: completion)
	}

	func close() {
		crypto = nil
	}

	func test() -> String? {
		guard let crypto = crypto else { return nil }
		do {
			let categories: [Category?] = try database.select(columns: ["ID", "Name", "ParentCategoryID"], fromTable: "spbwlt_Category", where: "ParentCategoryID = ''")
			return categories.map {
				guard let bytes: [UInt8] = $0?.name else { return "<data error>" }
				let data = Data(bytes)
				guard let plaintext = crypto.decryptString(data: data) else { return "<decryption error>" }
				return plaintext
			}.joined(separator: "\n")
		}
		catch {
			return error.localizedDescription
		}
	}

	private var crypto: CryptoProvider?

	struct Category: SQLiteDatabaseRow {
		let id: String
		let name: [UInt8]
		let parent: String

		static func decode(from statement: OpaquePointer, column: Int32 = 0) -> SwlDatabase.Category? {
			guard let id: String = .decode(from: statement, column: column) else { return nil }
			guard let name: [UInt8] = .decode(from: statement, column: column + 1) else { return nil }
			guard let parent: String = .decode(from: statement, column: column + 2) else { return nil }
			return .init(id: id, name: name, parent: parent)
		}
	}
}
