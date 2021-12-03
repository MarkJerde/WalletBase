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
			let categories: [Category] = try database.select(columns: ["ID", "Name", "ParentCategoryID"], fromTable: Tables.categories, where: "ID \(categoryId.queryCondition)").compactMap { $0 }

			// Filter matches since the swl category ID cannot be uniquely searched for in an SQL query.
			let filteredCategories = categoryId.filter(results: categories, \.id)

			assert(filteredCategories.count < 2, "Unexpected to have 2+ matches after filtering.")

			// Find the category, if there is one.
			guard let category = filteredCategories.first else { return nil }

			// Decrypt the category name.
			let bytes: [UInt8] = category.name
			let data = Data(bytes)
			guard let plaintext = crypto.decryptString(data: data) else { return nil }

			return .init(name: plaintext, type: .category(category: category))
		}
		catch {
			return nil
		}
	}

	/// Obtains the decrypted items in a given category, or the root category if nil.
	/// - Parameter category: The category.
	/// - Returns: The items.
	func items(in category: Category?) -> [Item] {
		let categories = categories(in: category)
		guard let category = category else {
			return categories
		}
		let cards = cards(in: category)
		return categories + cards
	}

	/// Obtains the decrypted category items in a given category, or the root category if nil.
	/// - Parameter category: The category.
	/// - Returns: The items.
	func categories(in category: Category?) -> [Item] {
		guard let crypto = crypto else { return [] }
		do {
			// Find everything that matches.
			let categories: [Category] = try database.select(columns: ["ID", "Name", "ParentCategoryID"], fromTable: Tables.categories, where: "ParentCategoryID \(category?.id.queryCondition ?? "like ''")").compactMap { $0 }

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
				return .init(name: plaintext, type: .category(category: category))
			}
		}
		catch {
			return []
		}
	}

	/// Obtains the decrypted card items in a given category.
	/// - Parameter category: The category.
	/// - Returns: The items.
	func cards(in category: Category) -> [Item] {
		guard let crypto = crypto else { return [] }
		do {
			// Find everything that matches.
			let cards: [Card] = try database.select(columns: ["ID", "Name", "ParentCategoryID"], fromTable: Tables.cards, where: "ParentCategoryID \(category.id.queryCondition)").compactMap { $0 }

			// Filter matches since the swl category ID cannot be uniquely searched for in an SQL query.
			let filteredCards: [Card] = category.id.filter(results: cards, \.parent)

			// Decrypt the item names and return.
			return filteredCards.compactMap { card in
				let bytes: [UInt8] = card.name
				let data = Data(bytes)
				guard let plaintext = crypto.decryptString(data: data) else { return nil }
				return .init(name: plaintext, type: .card(card: card))
			}
		}
		catch {
			return []
		}
	}

	/// Obtains the encrypted card field values of a given card.
	/// - Parameter category: The category.
	/// - Returns: The items.
	func fieldValues(in card: Card) -> [CardFieldValue] {
		do {
			// Find everything that matches.
			let fieldValues: [CardFieldValue] = try database.select(columns: ["ID", "CardID", "TemplateFieldID", "ValueString"], fromTable: Tables.cardFieldValue, where: "CardID \(card.id.queryCondition)").compactMap { $0 }

			// Filter matches since the swl category ID cannot be uniquely searched for in an SQL query.
			let filteredCards: [CardFieldValue] = card.id.filter(results: fieldValues, \.cardId)

			return filteredCards
		}
		catch {
			return []
		}
	}

	/// The cryptography provider which can decrypt this wallet.
	private var crypto: CryptoProvider?

	private enum Tables: String, SQLiteTable {
		case categories = "spbwlt_Category"
		case cards = "spbwlt_Card"
		case cardFieldValue = "spbwlt_CardFieldValue"

		var name: String {
			return rawValue
		}
	}
}
