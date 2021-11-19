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
			let byteses = try database.select(columns: ["Name"], fromTable: "spbwlt_Category", where: "ParentCategoryID = ''")
			return byteses.map {
				guard let bytes: [UInt8] = $0 else { return "<data error>" }
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
}
