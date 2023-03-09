//
//  SwlDatabase.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/10/21.
//

import AppKit
import Foundation

protocol SwlIdentifiable {
	var id: SwlDatabase.SwlID { get }
}

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
		// Ensure the user is warned as to the safety of this software. This is a two-part mechanism. First we hash the file to create a UserDefaults key and if it failed to hash or the key was not true in UserDefaults, show the alert. If the user does not accept the alert, opening the wallet fails and the completion is called accordingly. Second, after the user has accepted the alert and provided a password capable of unlocking the file, then save true to that UserDefaults key. This provides a disclaimer before the user has provided any sensitive data (the encrypted file is not sensitive because they already have that readable by their account on the device) and does not persist acceptance until unlocking verifies that a person with access to the file contents provided that acceptance. This will continue showing the disclaimer for each file until all are accepted so that if multiple users shared a device they would each be independently warned.
		if !hasAcceptedTerms(for: database.file) {
			let alert = NSAlert()
			alert.messageText = "Use at your own risk!"
			alert.informativeText = "THE AUTHOR SUPPLIES THIS SOFTWARE \"AS IS\", AND MAKES NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND. This software was written without expertise in data security and may have vulnerabilities which enable other software to capture your decrypted information, defects which result in a loss of data, or other ill effects. Users are encouraged to read the source code, made publicly available."
			alert.addButton(withTitle: "Accept")
			alert.addButton(withTitle: "Cancel")
			let response = alert.runModal()
			guard response == NSApplication.ModalResponse.alertFirstButtonReturn else {
				completion(false)
				return
			}
		}

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

			// Store that the user has seen the warning, now that we know the user is someone who can unlock the file.
			self.acceptTerms(for: self.database.file)

			self.isUnlocked = true
			completion(true)
		})
	}

	private func disclaimerKey(for file: URL) -> String? {
		guard let sha256 = database.file.contentSHA256 else { return nil }
		return "acceptedTerms_\(sha256.compactMap { String(format: "%02x", $0) }.joined())"
	}

	private func hasAcceptedTerms(for file: URL) -> Bool {
		guard let disclaimerKey = disclaimerKey(for: file) else { return false }
		return UserDefaults.standard.bool(forKey: disclaimerKey)
	}

	private func acceptTerms(for file: URL) {
		guard let disclaimerKey = disclaimerKey(for: file) else { return }
		UserDefaults.standard.set(true, forKey: disclaimerKey)
	}

	/// Closes the wallet by discarding the decryption key.
	func close() {
		// Update the terms acceptance if the file was edited.
		if isUnlocked,
		   !hasAcceptedTerms(for: database.file)
		{
			acceptTerms(for: database.file)
		}
		isUnlocked = false
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

			assert(categories.count < 2, "Unexpected to have 2+ matches after filtering.")

			// Find the category, if there is one.
			guard let category = categories.first else { return nil }

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

			// Decrypt the item names and return.
			return categories.compactMap { category in
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

			// Decrypt the item names and return.
			return cards.compactMap { card in
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

	/// Obtains the decrypted card items in a given category.
	/// - Parameter category: The category.
	/// - Returns: The items.
	func cards(in searchString: String) -> [Item] {
		guard let crypto = crypto,
		      let encryptedSearchStringData = crypto.encrypt(searchString) else { return [] }

		let encryptedSearchString = SQLiteDataItem(dataValue: encryptedSearchStringData)

		do {
			// Find everything that matches.
			let cards: [Card] = try database.select(where: "Name is \(encryptedSearchString.asBlob)").compactMap { $0 }

			// Decrypt the item names and return.
			return cards.compactMap { card in
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

			return fieldValues.first
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

			return fieldValues
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

			return fieldValues
		}
		catch {
			return []
		}
	}

	enum Error: Swift.Error {
		case writeFailure
		case writeFailureIndeterminite
	}

	func update(fieldValues: [SwlID: (String, SwlID)],
	            editedDescription: String?,
	            in cardId: SwlID) throws
	{
		do {
			try database.beginTransaction()
		}
		catch {
			throw Error.writeFailure
		}

		for (id, value) in fieldValues {
			let templateFieldId = value.1
			let value = value.0
			guard !id.value.isEmpty || !value.isEmpty else {
				// Creating a new empty field. We will just ignore this.
				continue
			}

			guard !value.isEmpty else {
				// Delete field.
				try database.delete(from: CardFieldValue.table, where: "id \(id.queryCondition)")
				continue
			}

			guard !id.value.isEmpty else {
				// Create new field.
				guard let newId = SwlID.new,
				      let encryptedValue = crypto?.encrypt(value)
				else {
					throw Error.writeFailure
				}

				try insert(value: CardFieldValue(id: newId,
				                                 cardId: cardId,
				                                 templateFieldId: templateFieldId,
				                                 value: [UInt8](encryptedValue)))
				continue
			}

			try update(id: id) { current -> CardFieldValue? in
				guard let encryptedValue = crypto?.encrypt(value) else {
					return nil
				}

				return CardFieldValue(id: current.id,
				                      cardId: current.cardId,
				                      templateFieldId: current.templateFieldId,
				                      value: [UInt8](encryptedValue))
			}
		}

		if let editedDescription {
			try update(id: cardId) { current -> Card? in
				let encryptedValue: Data?
				if editedDescription.isEmpty {
					// Description is documented as nullable, but in practice a X'00000000' value is used rather than NULL.
					encryptedValue = Data(count: 4)
				}
				else {
					guard let encrypted = crypto?.encrypt(editedDescription) else {
						return nil
					}
					encryptedValue = encrypted
				}

				return Card(id: current.id,
				            name: current.name,
				            description: (encryptedValue == nil) ? nil : [UInt8](encryptedValue!),
				            cardViewID: current.cardViewID,
				            hasOwnCardView: current.hasOwnCardView,
				            templateID: current.templateID,
				            parent: current.parent,
				            iconID: current.iconID,
				            hitCount: current.hitCount,
				            syncID: current.syncID,
				            createSyncID: current.createSyncID)
			}
		}

		do {
			try database.commitTransaction()
		}
		catch {
			throw Error.writeFailureIndeterminite
		}
	}

	private func insert<T: SQLiteDatabaseItem & SQLiteQueryReadWritable & SwlIdentifiable>(
		value: T) throws
	{
		do {
			try database.insert(record: value)
		}
		catch {
			do {
				try database.rollbackTransaction()
			}
			catch {
				if error is SQLiteDatabase.DatabaseError {
					throw Error.writeFailure // We can't be sure it is indeterminite, since SQLite returns an error in some rollback cases which occur after an automatically rollbacked error.
				}
				throw Error.writeFailureIndeterminite // This should be indeterminite, since it did not fail in SQLite.
			}
			throw Error.writeFailure
		}
	}

	private func update<T: SQLiteDatabaseItem & SQLiteQueryReadWritable & SwlIdentifiable>(id: SwlID,
	                                                                                       transform: (T) -> T?) throws
	{
		let current: [T]? = try? database.select(where: "id \(id.queryCondition)").compactMap { $0 }
		guard let current = current,
		      current.count == 1,
		      let current = current.first,
		      current.id == id,
		      let updated = transform(current)
		else {
			do {
				try database.rollbackTransaction()
			}
			catch {
				throw Error.writeFailureIndeterminite // This should be indeterminite, since it did not fail in SQLite.
			}
			throw Error.writeFailure
		}

		do {
			try database.update(record: updated, from: current)
		}
		catch {
			do {
				try database.rollbackTransaction()
			}
			catch {
				if error is SQLiteDatabase.DatabaseError {
					throw Error.writeFailure // We can't be sure it is indeterminite, since SQLite returns an error in some rollback cases which occur after an automatically rollbacked error.
				}
				throw Error.writeFailureIndeterminite // This should be indeterminite, since it did not fail in SQLite.
			}
			throw Error.writeFailure
		}
	}

	/// Obtains the encrypted template field of a given id.
	/// - Parameter templateFieldId: The template field ID.
	/// - Returns: The template field.
	func templateField(forId templateFieldId: SwlID) -> TemplateField? {
		do {
			// Find everything that matches.
			let templateFields: [TemplateField] = try database.select(where: "ID \(templateFieldId.queryCondition)").compactMap { $0 }

			if templateFields.count > 1 {
				NSLog("multiple template fields \(templateFields)")
			}

			return templateFields.first
		}
		catch {
			return nil
		}
	}

	/// Obtains the encrypted template fields of a given template ID.
	/// - Parameter templateId: The template ID.
	/// - Returns: The template fields.
	func templateFields(forTemplateId templateId: SwlID) -> [TemplateField] {
		do {
			// Find everything that matches.
			let templateFields: [TemplateField] = try database.select(where: "\(TemplateField.Column.templateID) \(templateId.queryCondition)").compactMap { $0 }

			return templateFields
		}
		catch {
			return []
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
	private var isUnlocked = false

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
