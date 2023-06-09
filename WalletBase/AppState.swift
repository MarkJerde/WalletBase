//
//  AppState.swift
//  WalletBase
//
//  Created by Mark Jerde on 6/8/23.
//

import AppKit

class AppState: ObservableObject {
	init() {}

	var canCreateNewCard = false
	var canCreateNewFolder = false

	enum MyState {
		case loadingDatabase
		case buttonToUnlock(databaseFile: URL)
		case unlocking(database: SwlDatabase)
		case passwordPrompt(database: SwlDatabase, completion: (String) -> Void)
		case browseContent(database: SwlDatabase)
		case viewCard(database: SwlDatabase)
		indirect case error(message: String, then: MyState)
	}

	@Published var state: MyState = .loadingDatabase {
		// FIXME: Letting others set the state is a little sloppy. A private(set) would be better but further changes are needed to make that happen.
		didSet {
			setMenuEnables()

			switch state {
			case .loadingDatabase,
			     .buttonToUnlock:
				// Clear auto-lock.
				ActivityMonitor.shared.onInactivity = nil
			case .browseContent(let database),
			     .viewCard(let database):
				// Set auto-lock if not yet set.
				guard ActivityMonitor.shared.onInactivity == nil else { return }

				ActivityMonitor.shared.onInactivity = {
					self.lock(database: database)
				}
			case .unlocking,
			     .passwordPrompt,
			     .error:
				break
			}
		}
	}

	func setMenuEnables() {
		let newCanCreateNewCard: Bool
		switch state {
		case .browseContent:
			newCanCreateNewCard = category != nil
		default:
			newCanCreateNewCard = false
		}
		guard canCreateNewCard != newCanCreateNewCard else { return }
		canCreateNewCard = newCanCreateNewCard
	}

	struct Prompt {
		let title: String?
		let message: String?
		let options: [MenuView.Option]
		let handler: (String, [String: String]) -> Void
	}

	@Published var prompt: Prompt? = nil

	func currentDatabaseAndCategory() -> (SwlDatabase, SwlDatabase.Category?)? {
		let database: SwlDatabase
		switch state {
		case .browseContent(let aDatabase):
			database = aDatabase
		default:
			return nil
		}
		let resultCategory: SwlDatabase.Category?
		if let category,
		   case .category(let swlCategory) = category.itemType
		{
			resultCategory = swlCategory
		} else {
			resultCategory = nil
		}
		return (database, resultCategory)
	}

	func showPromptForNewCard() {
		guard let (database, createInCategory) = currentDatabaseAndCategory() else { return }
		promptToCreateNewFolderOrCard(isNewFolder: false,
		                              in: database,
		                              category: createInCategory)
	}

	func showPromptForNewFolderOrCard() {
		guard let (database, createInCategory) = currentDatabaseAndCategory() else { return }
		prompt = newFolderOrCardPrompt(in: database, category: createInCategory)
	}

	func newFolderOrCardPrompt(in database: SwlDatabase, category: SwlDatabase.Category?) -> Prompt {
		let options: [CreateNew]
		if category == nil {
			options = [
				.folder,
				.cancel,
			]
		} else {
			options = CreateNew.allCases
		}
		return Self.promptToCreateNew(options: options) { response in
			let isNewFolder = response == CreateNew.folder.rawValue.capitalized
			self.promptToCreateNewFolderOrCard(isNewFolder: isNewFolder,
			                                   in: database,
			                                   category: category)
		} cancel: {
			self.prompt = nil
		}
	}

	private static func promptToCreateNew(options: [CreateNew], completion: @escaping (String) -> Void, cancel: @escaping () -> Void) -> Prompt {
		.init(
			title: "Create new:",
			message: nil,
			options: options
				.map {
					$0.rawValue.capitalized
				}
				.map {
					.button(text: $0)
				},
			handler: { selection, _ in
				guard selection != CreateNew.cancel.rawValue.capitalized else {
					cancel()
					return
				}

				completion(selection)
			})
	}

	private func promptToCreateNewFolderOrCard(isNewFolder: Bool, in database: SwlDatabase, category: SwlDatabase.Category?) {
		let prompt: String
		let fieldName: String
		if isNewFolder {
			prompt = "Create new folder"
			fieldName = "Folder name"
		} else {
			prompt = "Create new card"
			fieldName = "Card name"
		}
		self.prompt = Self.promptForField(
			prompt: prompt,
			fieldName: fieldName,
			completion: { newName in
				if isNewFolder {
					self.createFolder(named: newName, in: database, category: category)
				} else if let category {
					self.createCard(named: newName, in: database, category: category)
				}
				self.prompt = nil
				// Navigate to reload the content.
				self.navigate(toDatabase: database, category: self.category, card: nil)
			}, cancel: {
				self.prompt = nil
			}, error: { errorDetail in
				guard errorDetail.hasPrefix("missing: "),
				      let missingItem = errorDetail.components(separatedBy: "missing: ").last,
				      !missingItem.isEmpty
				else {
					self.prompt = .init(title: "Error",
					                    message: "An error occurred.",
					                    options: [
					                    	.button(text: "Okay"),
					                    ], handler: { _, _ in
					                    	self.prompt = nil
					                    })
					return
				}

				self.prompt = .init(title: "Error",
				                    message: "\(missingItem) is required.",
				                    options: [
				                    	.button(text: "Okay"),
				                    ], handler: { _, _ in
				                    	self.prompt = nil
				                    })
			})
	}

	private static func promptForField(prompt: String, fieldName: String, completion: @escaping (String) -> Void, cancel: @escaping () -> Void, error: @escaping (String) -> Void) -> Prompt {
		.init(
			title: prompt,
			message: nil,
			options: [
				.field(id: fieldName),
				.button(text: "Create"),
				.button(text: "Cancel"),
			],
			handler: { selection, fieldValues in
				guard selection != "Cancel" else {
					cancel()
					return
				}

				guard let value = fieldValues[fieldName],
				      !value.isEmpty
				else {
					error("missing: \(fieldName)")
					return
				}

				completion(value)
			})
	}

	@Published var category: SwlDatabase.Item?

	@Published var items: [SwlDatabase.Item] = []
	@Published var card: CardValuesComposite<SwlDatabase.SwlID>?
	@Published var cardIndex: Int?
	@Published var numCards: Int?

	@Published var restoreCategoryId: SwlDatabase.SwlID?
	@Published var restoreCardId: SwlDatabase.SwlID?

	func navigate(toDatabase database: SwlDatabase, category: SwlDatabase.Item? = nil, card: SwlDatabase.Card? = nil) {
		if category == nil,
		   card == nil,
		   restoreCategoryId != nil,
		   let category = database.categoryItem(forId: restoreCategoryId)
		{
			let cards: [SwlDatabase.Card] = items(of: category, in: database).compactMap { item in
				switch item.itemType {
				case .card(let card):
					return card
				default:
					return nil
				}
			}
			let card: SwlDatabase.Card?
			if let restoreCardId = restoreCardId {
				card = cards.first(where: { $0.id == restoreCardId })
			} else {
				card = nil
			}
			restoreCategoryId = nil
			restoreCardId = nil

			// Save numCards and cardIndex to restore later.
			let numCards = self.numCards
			let cardIndex = self.cardIndex

			navigate(toDatabase: database, category: category, card: card)

			// Restore `numCards` and `cardIndex` which will have been cleared by navigate(:::) since the category `items` are not retained while viewing a card and without that the count and index aren't determined by navigate(:::).
			self.numCards = numCards
			self.cardIndex = cardIndex

			return
		}

		ActivityMonitor.shared.didActivity()
		switch category?.itemType {
		case .category(let category):
			restoreCategoryId = category.id
		default:
			restoreCategoryId = nil
		}

		self.category = category

		if let card = card {
			restoreCardId = card.id
			let justCards = items.filter { item in
				switch item.itemType {
				case .card:
					return true
				default:
					return false
				}
			}
			let index = justCards.firstIndex { item in
				switch item.itemType {
				case .card(let aCard):
					return card == aCard
				default:
					return false
				}
			}
			numCards = justCards.count
			cardIndex = index
			items = []
			self.card = CardValuesComposite<SwlDatabase.SwlID>.card(for: card, database: database)
			state = .viewCard(database: database)
			return
		}
		restoreCardId = nil

		// Load category view content.
		items = items(of: category, in: database)
		numCards = nil
		cardIndex = nil
		state = .browseContent(database: database)
	}

	func navigate(toDatabase database: SwlDatabase, category: SwlDatabase.Item? = nil, index: Int) {
		guard let numCards = numCards else {
			return
		}

		let cards = items(of: category, in: database).filter { item in
			switch item.itemType {
			case .card:
				return true
			default:
				return false
			}
		}
		guard index < cards.count else { return }
		let card = cards[index]
		switch card.itemType {
		case .card(let card):
			navigate(toDatabase: database, category: category, card: card)
			// Restore `numCards` which will have been cleared by navigate(:::) since the category `items` are not retained while viewing a card and without that the index isn't determined by navigate(:::), and set the new index.
			self.numCards = numCards
			cardIndex = index
		default:
			break
		}
	}

	private func mostCommonID<T: SQLiteDatabaseItem>(in database: SwlDatabase, selecting select: (T) -> SwlDatabase.SwlID) -> SwlDatabase.SwlID? where T: SQLiteQuerySelectable {
		guard let records: [T] = try? database.database.select().compactMap({ $0 }) else {
			return nil
		}
		let ids = records.map { select($0) }
		let countedSet = NSCountedSet(array: ids)
		let mostFrequent = countedSet.max { countedSet.count(for: $0) < countedSet.count(for: $1) }
		return mostFrequent as? SwlDatabase.SwlID
	}

	private func createFolder(named: String, in database: SwlDatabase, category: SwlDatabase.Category?) {
		// FIXME: Need an iconID. Just pick the most common.
		guard let iconID = mostCommonID(in: database, selecting: { category in category.iconID } as (SwlDatabase.Category) -> SwlDatabase.SwlID),
		      // FIXME: Need an defaultTemplateID. Just pick the most common.
		      let defaultTemplateID = mostCommonID(in: database, selecting: { category in category.defaultTemplateID } as (SwlDatabase.Category) -> SwlDatabase.SwlID)
		else {
			return
		}

		guard let encryptedName = database.encrypt(text: named),
		      let description = database.encrypt(text: ""), // Strings are typically nullable in the swl database but in practice a X'00000000' value is used rather than NULL.
		      let categoryID = SwlDatabase.SwlID.new else { return }
		let parent = category?.id ?? .rootCategory
		let category = SwlDatabase.Category(id: categoryID,
		                                    name: [UInt8](encryptedName),
		                                    description: [UInt8](description),
		                                    iconID: iconID,
		                                    defaultTemplateID: defaultTemplateID,
		                                    parent: parent,
		                                    syncID: -1,
		                                    createSyncID: -1)

		do {
			try database.insert(value: category)
		} catch {
			if let error = error as? SwlDatabase.Error {
				switch error {
				case .writeFailureIndeterminite:
					let alert = NSAlert()
					alert.messageText = "Save Failed"
					alert.informativeText = "Something went wrong while trying to save. Enough so that the wallet may be corrupted. You should probably at least close the wallet, reopen it, and check to see if things look right."
					alert.alertStyle = .critical
					alert.addButton(withTitle: "Close Wallet")
					alert.addButton(withTitle: "Take More Risks")
					guard alert.runModal() == .alertFirstButtonReturn else { return }
					// folder = nil
					lock(database: database)
					return
				default:
					break
				}
			}
			showFailedToSaveAlert()
			return
		}
	}

	private func createCard(named: String, in database: SwlDatabase, category: SwlDatabase.Category) {
		// FIXME: Need a template ID.
		guard let templateID = mostCommonID(in: database, selecting: { category in category.templateID } as (SwlDatabase.Card) -> SwlDatabase.SwlID),
		      // FIXME: Need an iconID. Just pick the most common.
		      let iconID = mostCommonID(in: database, selecting: { category in category.iconID } as (SwlDatabase.Card) -> SwlDatabase.SwlID)
		else {
			return
		}

		guard let encryptedName = database.encrypt(text: named),
		      let description = database.encrypt(text: ""), // Strings are typically nullable in the swl database but in practice a X'00000000' value is used rather than NULL.
		      let cardID = SwlDatabase.SwlID.new,
		      let cardViewID = SwlDatabase.SwlID.new else { return }
		let card = SwlDatabase.Card(id: cardID,
		                            name: [UInt8](encryptedName),
		                            description: [UInt8](description),
		                            cardViewID: cardViewID,
		                            hasOwnCardView: 0,
		                            templateID: templateID,
		                            parent: category.id,
		                            iconID: iconID,
		                            hitCount: 0,
		                            syncID: -1,
		                            createSyncID: -1)

		do {
			try database.insert(value: card)
		} catch {
			if let error = error as? SwlDatabase.Error {
				switch error {
				case .writeFailureIndeterminite:
					let alert = NSAlert()
					alert.messageText = "Save Failed"
					alert.informativeText = "Something went wrong while trying to save. Enough so that the wallet may be corrupted. You should probably at least close the wallet, reopen it, and check to see if things look right."
					alert.alertStyle = .critical
					alert.addButton(withTitle: "Close Wallet")
					alert.addButton(withTitle: "Take More Risks")
					guard alert.runModal() == .alertFirstButtonReturn else { return }
					// folder = nil
					lock(database: database)
					return
				default:
					break
				}
			}
			showFailedToSaveAlert()
			return
		}
	}

	func items(of category: SwlDatabase.Item?, in database: SwlDatabase) -> [SwlDatabase.Item] {
		var swlCategory: SwlDatabase.Category?
		if let category = category,
		   case .category(let category) = category.itemType
		{
			swlCategory = category
		}
		let categories = database.categories(in: swlCategory).sorted(by: \.name)
		let cards: [SwlDatabase.Item]
		if let swlCategory = swlCategory {
			cards = database.cards(in: swlCategory).sorted(by: \.name)
		} else {
			cards = []
		}
		return categories + cards
	}

	func items(of searchString: String, in database: SwlDatabase) -> [SwlDatabase.Item] {
		database.cards(in: searchString).sorted(by: \.name)
	}

	func showFailedToSaveAlert() {
		let alert = NSAlert()
		alert.messageText = "Save Failed"
		alert.informativeText = "Something went wrong while trying to save. Please try again."
		alert.alertStyle = .warning
		alert.addButton(withTitle: "OK")
		_ = alert.runModal()
	}

	func lock(database: SwlDatabase) {
		items = []
		category = nil
		database.close()
		state = .buttonToUnlock(databaseFile: database.file)
	}

	private enum CreateNew: String, CaseIterable {
		case card
		case folder
		case cancel
	}

#if DEBUG
	static var didAutoUnlockSampleWallet = false
#endif

	func loadFile() {
		DispatchQueue.main.async {
			let dialog = NSOpenPanel()

			dialog.title = "Choose an .swl file"
			dialog.showsResizeIndicator = true
			dialog.showsHiddenFiles = false
			dialog.canChooseDirectories = false
			dialog.canCreateDirectories = false
			dialog.allowsMultipleSelection = false
			dialog.allowedFileTypes = ["swl"]

			guard dialog.runModal() == .OK else {
				self.state = .error(message: "Unable to open file.",
				                    then: .loadingDatabase)
				return
			}

			guard let url = dialog.url else {
				self.state = .error(message: "No file selected.",
				                    then: .loadingDatabase)
				return
			}

			self.state = .buttonToUnlock(databaseFile: url)
		}
	}
}
