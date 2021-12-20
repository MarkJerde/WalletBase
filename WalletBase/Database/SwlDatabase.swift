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
		crypto.unlock(password: password, completion: { success in
			// Attempt to verify the password was correct before calling our caller's completion with success equals true.
			guard success else {
				completion(false)
				return
			}

			do {
				// There doesn't appear to be any mechanism for password validation in the database content. One workaround is to assume that the template fields must include one with the name "Password". This seems questionable in the cases of English not being the language of the content or the database being used to secure things that do not include passwords, but it's what we have so we will use it.
				let templateFields: [TemplateField] = try self.database.select().compactMap { $0 }
				let index = templateFields.firstIndex {
					self.decryptString(bytes: $0.name) == "Password"
				}
				guard index != nil else {
					completion(false)
					return
				}
			}
			catch {
				completion(false)
				return
			}

			completion(true)
		})
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
			let categories: [Category] = try database.select(where: "ID \(categoryId.queryCondition)").compactMap { $0 }

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
			let categories: [Category] = try database.select(where: "ParentCategoryID \(category?.id.queryCondition ?? "like ''")").compactMap { $0 }

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
			let cards: [Card] = try database.select(where: "ParentCategoryID \(category.id.queryCondition)").compactMap { $0 }

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

	/// Obtains the encrypted card description of a given card.
	/// - Parameter category: The category.
	/// - Returns: The description.
	func description(in card: Card) -> CardDescription? {
		do {
			// Find everything that matches.
			let fieldValues: [CardDescription] = try database.select(where: "ID \(card.id.queryCondition)").compactMap { $0 }

			// Filter matches since the swl category ID cannot be uniquely searched for in an SQL query.
			let filteredCards: [CardDescription] = card.id.filter(results: fieldValues, \.id)

			return filteredCards.first
		}
		catch {
			return nil
		}
	}

	/// Obtains the encrypted card attachments of a given card.
	/// - Parameter category: The category.
	/// - Returns: The items.
	func attachments(in card: Card) -> [CardAttachment] {
		do {
			// Find everything that matches.
			let fieldValues: [CardAttachment] = try database.select(where: "CardID \(card.id.queryCondition)").compactMap { $0 }

			// Filter matches since the swl category ID cannot be uniquely searched for in an SQL query.
			let filteredCards: [CardAttachment] = card.id.filter(results: fieldValues, \.cardId)

			return filteredCards
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
			let fieldValues: [CardFieldValue] = try database.select(where: "CardID \(card.id.queryCondition)").compactMap { $0 }

			// Filter matches since the swl category ID cannot be uniquely searched for in an SQL query.
			let filteredCards: [CardFieldValue] = card.id.filter(results: fieldValues, \.cardId)

			return filteredCards
		}
		catch {
			return []
		}
	}

	/// Obtains the encrypted template field of a given id.
	/// - Parameter category: The category.
	/// - Returns: The items.
	func templateField(forId templateFieldId: SwlID) -> TemplateField? {
		do {
			// Find everything that matches.
			let templateFields: [TemplateField] = try database.select(where: "ID \(templateFieldId.queryCondition)").compactMap { $0 }

			// Filter matches since the swl category ID cannot be uniquely searched for in an SQL query.
			let filteredtemplateFields: [TemplateField] = templateFieldId.filter(results: templateFields, \.id)

			if filteredtemplateFields.count > 1 {
				NSLog("multiple template fields \(filteredtemplateFields)")
			}

			return filteredtemplateFields.first
		}
		catch {
			return nil
		}
	}

	func decryptString(bytes: [UInt8]) -> String? {
		let data = Data(bytes)
		return crypto?.decryptString(data: data)
	}

	func decryptData(bytes: [UInt8]) -> Data? {
		let data = Data(bytes)
		return crypto?.decryptData(data: data)
	}

	/// The cryptography provider which can decrypt this wallet.
	private var crypto: CryptoProvider?

	enum Tables: String, SQLiteTable {
		case databaseVersion = "spb_DatabaseVersion" // TODO:
		case wallet = "spbwlt_Wallet" // TODO:
		case categories = "spbwlt_Category"
		case cards = "spbwlt_Card"
		case cardFieldValues = "spbwlt_CardFieldValue"
		case cardAttachments = "spbwlt_CardAttachment"
		case cardViews = "spbwlt_CardView" // TODO:
		case cardViewFields = "spbwlt_CardViewField" // TODO:
		case templates = "spbwlt_Template" // TODO:
		case templateFields = "spbwlt_TemplateField"
		case templateFieldTypes = "spbwlt_TemplateFieldType" // TODO:
		case icon = "spbwlt_Icon" // TODO:
		case image = "spbwlt_Image" // TODO:

		var name: String {
			return rawValue
		}
	}
}
