//
//  SwlDatabase.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/10/21.
//

import Foundation

/// An object providing access to an swl password wallet database.
class SwlDatabase {
	/// The SQLite database representing the encrypted wallet.
	let database: SQLiteDatabase
	/// The wallet file.
	var file: URL { database.file }

	/// Creates and returns an swl wallet object for the specified wallet file.
	/// - Parameter file: The wallet file.
	init(file: URL) {
		self.database = SQLiteDatabase(file: file)
	}

	/// Opens the wallet by obtaining the necessary credentials.
	/// - Parameters:
	///   - password: A closure to initiate acquisition of the password which takes a closure to call once the password has been acquired.
	///   - completion: A closure to call after the decryption key is established or will not be established.
	func open(password: (@escaping (String) -> Void) -> Void, completion: @escaping (Bool) -> Void) {
		let crypto = SwlCrypto()
		self.crypto = crypto
		crypto.unlock(password: password, completion: completion)
	}

	/// Closes the wallet by discarding the decryption key.
	func close() {
		crypto = nil
	}

	/// Obtains the decrypted category item for a given category ID.
	///
	/// This allows for minimized lifespans of decrypted data by enabling lookup of the data from the ID.
	/// - Parameter categoryId: The category ID.
	/// - Returns: The item, or nil if not found.
	func categoryItem(forId categoryId: SwlID?) -> Item? {
		guard let categoryId = categoryId,
		      let crypto = crypto else { return nil }
		do {
			// Find everything that matches.
			let categories: [Category] = try database.select(columns: ["ID", "Name", "ParentCategoryID"], fromTable: "spbwlt_Category", where: "ID \(categoryId.queryCondition)").compactMap { $0 }

			// Filter matches since the swl category ID cannot be uniquely searched for in an SQL query.
			let filteredCategories = categoryId.filter(results: categories, \.id)

			assert(filteredCategories.count < 2, "Unexpected to have 2+ matches after filtering.")

			// Find the category, if there is one.
			guard let category = filteredCategories.first else { return nil }

			// Decrypt the category name.
			let bytes: [UInt8] = category.name
			let data = Data(bytes)
			guard let plaintext = crypto.decryptString(data: data) else { return nil }

			return .init(name: plaintext, category: category)
		}
		catch {
			return nil
		}
	}

	/// Obtains the decrypted items in a given category, or the root category if nil.
	/// - Parameter category: The category.
	/// - Returns: The items.
	func items(in category: Category?) -> [Item] {
		guard let crypto = crypto else { return [] }
		do {
			// Find everything that matches.
			let categories: [Category] = try database.select(columns: ["ID", "Name", "ParentCategoryID"], fromTable: "spbwlt_Category", where: "ParentCategoryID \(category?.id.queryCondition ?? "like ''")").compactMap { $0 }

			// Filter matches since the swl category ID cannot be uniquely searched for in an SQL query.
			let filteredCategories: [Category]
			if let category = category {
				filteredCategories = category.id.filter(results: categories, \.parent)
			}
			else {
				filteredCategories = categories
			}

			// Decrypt the item names and return.
			return filteredCategories.compactMap { category in
				let bytes: [UInt8] = category.name
				let data = Data(bytes)
				guard let plaintext = crypto.decryptString(data: data) else { return nil }
				return .init(name: plaintext, category: category)
			}
		}
		catch {
			return []
		}
	}

	/// The cryptography provider which can decrypt this wallet.
	private var crypto: CryptoProvider?
}
