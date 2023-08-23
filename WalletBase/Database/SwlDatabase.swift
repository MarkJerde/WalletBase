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
			Alert.useAtYourOwnRisk.show { response in
				guard response == "Accept" else {
					completion(false)
					return
				}
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
				/* Harvest SwlIds for analysis:
				 let templateFieldsToPrint: [TemplateField] = try self.database.select()
				 	.compactMap { $0 }
				 templateFieldsToPrint.forEach { NSLog("swlid: \($0.id.hexString) TemplateField(\(self.decryptString(bytes: $0.name) ?? "nil"))") }
				 let cardsToPrint: [Card] = try self.database.select()
				 	.compactMap { $0 }
				 cardsToPrint.forEach { NSLog("swlid: \($0.id.hexString) Card(\(self.decryptString(bytes: $0.name) ?? "nil"))") }
				 let cardAttachmentsToPrint: [CardAttachment] = try self.database.select()
				 	.compactMap { $0 }
				 cardAttachmentsToPrint.forEach { NSLog("swlid: \($0.id.hexString) CardAttachment(\(self.decryptString(bytes: $0.name) ?? "nil"))") }
				 let cardDescriptionsToPrint: [CardDescription] = try self.database.select()
				 	.compactMap { $0 }
				 cardDescriptionsToPrint.forEach { NSLog("swlid: \($0.id.hexString) CardDescription(\(self.decryptString(bytes: $0.description ?? []) ?? "nil"))") }
				 let cardFieldValuesToPrint: [CardFieldValue] = try self.database.select()
				 	.compactMap { $0 }
				 cardFieldValuesToPrint.forEach { NSLog("swlid: \($0.id.hexString) CardFieldValue(\($0.templateFieldId.hexString) \($0.cardId.hexString))") }
				 let categorysToPrint: [Category] = try self.database.select()
				 	.compactMap { $0 }
				 categorysToPrint.forEach { NSLog("swlid: \($0.id.hexString) Category(\(self.decryptString(bytes: $0.name) ?? "nil"))") }
				 let templatesToPrint: [Template] = try self.database.select()
				 	.compactMap { $0 }
				 templatesToPrint.forEach { NSLog("swlid: \($0.id.hexString) Template(\(self.decryptString(bytes: $0.name) ?? "nil"))") }
				  */

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

	/// Obtains the decrypted card items matching a given search string.
	/// - Parameter searchString: The string to search.
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
		case stillNeeded
	}

	func encrypt(text: String, emptyIsNull: Bool = false) -> Data? {
		let encryptedValue: Data?
		if text.isEmpty {
			if emptyIsNull {
				return nil
			}
			// Strings are typically nullable in the swl database but in practice a X'00000000' value is used rather than NULL.
			encryptedValue = Data(count: 4)
		}
		else {
			guard let encrypted = crypto?.encrypt(text) else {
				return nil
			}
			encryptedValue = encrypted
		}
		return encryptedValue
	}

	enum IDType: Hashable {
		case new(SwlID)
		case existing(SwlID)

		var id: SwlID {
			switch self {
			case .new(let id),
			     .existing(let id):
				return id
			}
		}
	}

	func update(fieldValues: [IDType: (String, SwlID)],
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
			let isNewRow: Bool
			switch id {
			case .new:
				isNewRow = true
			default:
				isNewRow = false
			}
			guard isNewRow || !id.id.value.isEmpty || !value.isEmpty else {
				// Creating a new empty field. We will just ignore this.
				continue
			}

			guard !value.isEmpty else {
				// Delete field.
				try database.delete(from: CardFieldValue.table, where: "id \(id.id.queryCondition)")
				continue
			}

			guard !(isNewRow || id.id.value.isEmpty) else {
				// Create new field.
				guard let newId = isNewRow ? id.id : SwlID.new,
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

			try update(id: id.id) { current -> CardFieldValue? in
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
				let encryptedValue = encrypt(text: editedDescription)

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

	func insert<T: SQLiteDatabaseItem & SQLiteQueryReadWritable & SwlIdentifiable>(
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

	func update<T: SQLiteDatabaseItem & SQLiteQueryReadWritable & SwlIdentifiable>(id: SwlID,
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

	func delete<T: SQLiteDatabaseItem & SQLiteQueryReadWritable & SwlIdentifiable>(
		value: T) throws
	{
		do {
			if let card = value as? Card {
				do {
					try database.beginTransaction()
				}
				catch {
					throw Error.writeFailure
				}

				let fieldValues = fieldValues(in: card)

				for fieldValue in fieldValues {
					try database.delete(from: CardFieldValue.table, where: "id \(fieldValue.id.queryCondition)")
				}

				try database.delete(from: Card.table, where: "id \(card.id.queryCondition)")

				try database.commitTransaction()
			}
			else if let category = value as? Category {
				// Ensure category is empty.
				guard cards(in: category).isEmpty,
				      categories(in: category).isEmpty
				else {
					throw Error.stillNeeded
				}

				// Delete category.
				try database.delete(from: Category.table, where: "id \(category.id.queryCondition)")
			}
		}
		catch Error.stillNeeded {
			throw Error.stillNeeded
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

	enum TemplateSort {
		case none
		case categoryDefault
		case cardUse
	}

	func templates(sort: TemplateSort = .none, category: Category? = nil) -> [[Template]] {
		do {
			// Find everything that matches.
			var templates: [Template] = try database.select().compactMap { $0 }

			// Sort by template name in the event of equal frequency.
			let secondarySort: ((SwlID, SwlID) -> Bool) = { lID, rID in
				guard let lTemplate = templates.first(where: { template in template.id == lID }),
				      let rTemplate = templates.first(where: { template in template.id == rID })
				else {
					return false
				}
				return (self.decryptString(bytes: lTemplate.name) ?? "") < (self.decryptString(bytes: rTemplate.name) ?? "")
			}

			let orderedTemplateIDs: [SwlID]
			switch sort {
			case .none:
				return [templates]
			case .categoryDefault:
				orderedTemplateIDs = frequencyOrderedIDs(selecting: { category in category.defaultTemplateID } as (Category) -> SwlID, secondarySort: secondarySort)
			case .cardUse:
				orderedTemplateIDs = frequencyOrderedIDs(selecting: { category in category.templateID } as (Card) -> SwlID, secondarySort: secondarySort)
			}

			// Sort templates by order of IDs.
			var orderedTemplates = orderedTemplateIDs.compactMap { id in templates.first(where: { $0.id == id }) }

			// Sort the remainder by name.
			templates.removeAll { template in orderedTemplates.contains { orderedTemplate in
				template.id == orderedTemplate.id
			} }
			templates.sort { (decryptString(bytes: $0.name) ?? "") < (decryptString(bytes: $1.name) ?? "") }

			if sort == .cardUse,
			   let category
			{
				// Get the default template ID, find the template for it and remove from both lists, then return three lists of the default, most common, and alphabetical.
				let defaultTemplateID = category.defaultTemplateID
				let findDefaultTemplate: (Template) -> Bool = { template in
					template.id == defaultTemplateID
				}
				let defaultTemplate = orderedTemplates.first(where: findDefaultTemplate) ?? templates.first(where: findDefaultTemplate)
				if let defaultTemplate {
					orderedTemplates.removeAll(where: findDefaultTemplate)
					templates.removeAll(where: findDefaultTemplate)
					return [[defaultTemplate], orderedTemplates, templates]
				}
			}

			return [orderedTemplates, templates]
		}
		catch {
			return [[], []]
		}
	}

	/// Obtains the encrypted template of a given id.
	/// - Parameter templateId: The template ID.
	/// - Returns: The template.
	func template(forId templateId: SwlID) -> Template? {
		do {
			// Find everything that matches.
			let templates: [Template] = try database.select(where: "ID \(templateId.queryCondition)").compactMap { $0 }

			if templates.count > 1 {
				NSLog("multiple templates \(templates)")
			}

			return templates.first
		}
		catch {
			return nil
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

	private func countedSetOfIDs<T: SQLiteDatabaseItem>(selecting select: (T) -> SwlID) -> NSCountedSet where T: SQLiteQuerySelectable {
		guard let records: [T] = try? database.select().compactMap({ $0 }) else {
			return []
		}
		let ids = records.map { select($0) }
		let countedSet = NSCountedSet(array: ids)
		return countedSet
	}

	func frequencyOrderedIDs<T: SQLiteDatabaseItem>(selecting select: (T) -> SwlID, secondarySort: ((SwlID, SwlID) -> Bool)? = nil) -> [SwlID] where T: SQLiteQuerySelectable {
		let countedSet = countedSetOfIDs(selecting: select)
		let sorted = countedSet.sorted(by: {
			let lCount = countedSet.count(for: $0)
			let rCount = countedSet.count(for: $1)
			guard lCount == rCount else {
				// >= To sort frequency descending, while if they are equal our secondarySort will probably be name ascending.
				return lCount >= rCount
			}
			guard let secondarySort,
			      let lID = $0 as? SwlID,
			      let rID = $1 as? SwlID else { return false }
			return secondarySort(lID, rID)
		})
		return Array(sorted) as? [SwlID] ?? []
	}

	func mostCommonID<T: SQLiteDatabaseItem>(selecting select: (T) -> SwlID) -> SwlID? where T: SQLiteQuerySelectable {
		let countedSet = countedSetOfIDs(selecting: select)
		let mostFrequent = countedSet.max { countedSet.count(for: $0) < countedSet.count(for: $1) }
		return mostFrequent as? SwlID
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
		case databaseVersion = "spb_DatabaseVersion" // TODO: Needed, R/W for encryption upgrade.
		case wallet = "spbwlt_Wallet" // R/W
		case categories = "spbwlt_Category" // R/W
		case cards = "spbwlt_Card" // R/W
		case cardFieldValues = "spbwlt_CardFieldValue" // R/W
		case cardAttachments = "spbwlt_CardAttachment" // R/W
		case cardViews = "spbwlt_CardView" // TODO: Implement. Seems to be free of any encryption.
		case cardViewFields = "spbwlt_CardViewField" // TODO: Implement. Seems to be free of any encryption.
		case templates = "spbwlt_Template" // R/W
		case templateFields = "spbwlt_TemplateField" // R/W
		case templateFieldTypes = "spbwlt_TemplateFieldType" // TODO:
		case icon = "spbwlt_Icon" // R/W
		case image = "spbwlt_Image" // R/W

		var name: String {
			return rawValue
		}
	}
}
