//
//  AppState.swift
//  WalletBase
//
//  Created by Mark Jerde on 6/8/23.
//

import AppKit

class AppState: ObservableObject {
	init() {}

	// MARK: - State

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

	// MARK: - State Publishers

	@Published var category: SwlDatabase.Item?

	@Published var items: [SwlDatabase.Item] = []
	@Published var card: CardValuesComposite<SwlDatabase.SwlID>?
	@Published var cardIndex: Int?
	@Published var numCards: Int?

	// MARK: - Creation

	// Menu item flags
	var canCreateNewCard = false
	var canCreateNewFolder = false

	// Create sheet control
	@Published var currentCreatableTypes: [NewItemView.ItemType] = []
	@Published var shouldPresentCreateSheet = false

	/// A method which updates properties to inform and control creation options per the current state.
	func setMenuEnables() {
		let newCanCreateNewCard: Bool
		let newCanCreateNewFolder: Bool
		switch state {
		case .browseContent:
			newCanCreateNewCard = category != nil
			newCanCreateNewFolder = true
		default:
			newCanCreateNewCard = false
			newCanCreateNewFolder = false
		}
		if canCreateNewCard != newCanCreateNewCard {
			canCreateNewCard = newCanCreateNewCard
		}
		if canCreateNewFolder != newCanCreateNewFolder {
			canCreateNewFolder = newCanCreateNewFolder
		}
		if canCreateNewCard {
			if currentCreatableTypes.firstIndex(of: .card) == nil {
				currentCreatableTypes.append(.card)
			}
		} else {
			if let index = currentCreatableTypes.firstIndex(of: .card) {
				currentCreatableTypes.remove(at: index)
			}
		}
		if canCreateNewFolder {
			if currentCreatableTypes.firstIndex(of: .folder) == nil {
				currentCreatableTypes.insert(.folder, at: 0)
			}
		} else {
			if let index = currentCreatableTypes.firstIndex(of: .folder) {
				currentCreatableTypes.remove(at: index)
			}
		}
	}

	/// A method to invoke the creation sheet for Card creation only.
	func showPromptForNewCard() {
		currentCreatableTypes = [.card]
		shouldPresentCreateSheet = true
	}

	/// A method to invoke the creation sheet for Folder creation only.
	func showPromptForNewFolder() {
		currentCreatableTypes = [.folder]
		shouldPresentCreateSheet = true
	}

	/// Gets the appropriate template list for the specified creation type.
	/// - Parameter itemType: The type of item being created.
	/// - Returns: The list of templates.
	func getAvailableTemplates(itemType: NewItemView.ItemType) -> [NewItemView.Template] {
		guard let (database, category) = currentDatabaseAndCategory() else { return [] }
		var nextId = SwlDatabase.SwlID.zero
		let getNextId: () -> SwlDatabase.SwlID = {
			let newId = nextId
			nextId = nextId.next
			return newId
		}
		return database.templates(
			sort: itemType == .folder
				? .categoryDefault
				: .cardUse,
			category: category)
			.filter { !$0.isEmpty }
			.joined(separator: [.init(id: .zero, name: [], description: nil, cardViewID: .zero, syncID: 0, createSyncID: 0)])
			.map { template -> NewItemView.Template? in
				guard template.id != .zero else {
					return NewItemView.Template(id: getNextId(), name: nil)
				}
				guard let name = database.decryptString(bytes: template.name) else { return nil }
				return NewItemView.Template(id: template.id, name: name)
			}
			.compactMap { $0 }
	}

	/// Creates a folder with the provided name and default template ID in the current state.
	/// - Parameters:
	///   - named: The folder name.
	///   - defaultTemplateID: The default template ID for cards in this folder.
	func createFolder(named: String, defaultTemplateID: SwlDatabase.SwlID) {
		guard let (database, category) = currentDatabaseAndCategory() else { return }
		// FIXME: Need an iconID. Just pick the most common.
		guard let iconID = database.mostCommonID(selecting: { category in category.iconID } as (SwlDatabase.Category) -> SwlDatabase.SwlID)
		else {
			return
		}

		guard let encryptedName = database.encrypt(text: named),
		      let description = database.encrypt(text: ""), // Strings are typically nullable in the swl database but in practice a X'00000000' value is used rather than NULL.
		      let categoryID = SwlDatabase.SwlID.new else { return }
		let parent = category?.id ?? .rootCategory
		let newCategory = SwlDatabase.Category(id: categoryID,
		                                       name: [UInt8](encryptedName),
		                                       description: [UInt8](description),
		                                       iconID: iconID,
		                                       defaultTemplateID: defaultTemplateID,
		                                       parent: parent,
		                                       syncID: -1,
		                                       createSyncID: -1)

		do {
			try database.insert(value: newCategory)
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

	/// Creates a card with the provided name and template ID.
	/// - Parameters:
	///   - named: The card name.
	///   - templateID: The template ID.
	func createCard(named: String, templateID: SwlDatabase.SwlID) {
		guard let (database, category) = currentDatabaseAndCategory(),
		      let category else { return }
		// FIXME: Need an iconID. Just pick the most common.
		guard let iconID = database.mostCommonID(selecting: { category in category.iconID } as (SwlDatabase.Card) -> SwlDatabase.SwlID)
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

	// MARK: - Cut/Paste

	var currentCutItemType: ItemGridItemType?
	var currentCutItemId: SwlDatabase.SwlID?
	func cut(item: SwlDatabase.Item) {
		currentCutItemType = item.type
		switch item.itemType {
		case .card(let card):
			currentCutItemId = card.id
		case .category(let category):
			currentCutItemId = category.id
		}
	}

	func paste() -> String? {
		guard let currentCutItemType,
		      let currentCutItemId
		else {
			return "Nothing to paste."
		}
		guard let (database, category) = currentDatabaseAndCategory() else {
			return "No wallet open."
		}
		switch currentCutItemType {
		case .card:
			guard let category else {
				return "Cannot place cards in the topmost folder."
			}
			do {
				try database.update(id: currentCutItemId) { current -> SwlDatabase.Card? in
					SwlDatabase.Card(id: current.id,
					                 name: current.name,
					                 description: current.description,
					                 cardViewID: current.cardViewID,
					                 hasOwnCardView: current.hasOwnCardView,
					                 templateID: current.templateID,
					                 parent: category.id,
					                 iconID: current.iconID,
					                 hitCount: current.hitCount,
					                 syncID: current.syncID,
					                 createSyncID: current.createSyncID)
				}
			} catch {
				return "An error occurred while moving the card."
			}
		case .category:
			do {
				try database.update(id: currentCutItemId) { current -> SwlDatabase.Category? in
					SwlDatabase.Category(id: current.id,
					                     name: current.name,
					                     description: current.description,
					                     iconID: current.iconID,
					                     defaultTemplateID: current.defaultTemplateID,
					                     parent: category?.id ?? .null,
					                     syncID: current.syncID,
					                     createSyncID: current.createSyncID)
				}
			} catch {
				return "An error occurred while moving the folder."
			}
		default:
			return "Cannot paste files."
		}
		self.currentCutItemType = nil
		self.currentCutItemId = nil
		return nil
	}

	// MARK: - Navigation

	private var restoreCategoryId: SwlDatabase.SwlID?
	private var restoreCardId: SwlDatabase.SwlID?

	func restoreNavigation(inDatabase database: SwlDatabase) -> Bool {
		guard restoreCategoryId != nil,
		      let category = database.categoryItem(forId: restoreCategoryId)
		else {
			return false
		}

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

		return true
	}

	func navigate(toDatabase database: SwlDatabase, category: SwlDatabase.Item? = nil, card: SwlDatabase.Card? = nil) {
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

	func navigateToPrevious() {
		guard let (database, _) = currentDatabaseAndCategory(),
		      let cardIndex
		else {
			return
		}

		navigate(toDatabase: database, category: category, index: cardIndex - 1)
	}

	func navigateToNext() {
		guard let (database, _) = currentDatabaseAndCategory(),
		      let cardIndex
		else {
			return
		}

		navigate(toDatabase: database, category: category, index: cardIndex + 1)
	}

	private func navigate(toDatabase database: SwlDatabase, category: SwlDatabase.Item? = nil, index: Int) {
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

	private func items(of category: SwlDatabase.Item?, in database: SwlDatabase) -> [SwlDatabase.Item] {
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

	private func items(of searchString: String, in database: SwlDatabase) -> [SwlDatabase.Item] {
		database.cards(in: searchString).sorted(by: \.name)
	}

	// MARK: - Actions

	private var previousSearch: String?
	func search(searchString: String) {
		guard let (database, _) = currentDatabaseAndCategory(),
		      searchString != previousSearch else { return }
		previousSearch = searchString
		guard !searchString.isEmpty else {
			items = items(of: category, in: database)
			return
		}
		items = items(of: searchString, in: database)
		numCards = nil
		cardIndex = nil
		state = .browseContent(database: database)
	}

	func save(edits: [CardValuesComposite<SwlDatabase.SwlID>.CardValue: String], editedDescription: String?) -> Bool {
		guard let (database, _) = currentDatabaseAndCategory(),
		      let card
		else {
			showFailedToSaveAlert()
			return false
		}
		do {
			try database.update(
				fieldValues: Dictionary(uniqueKeysWithValues: edits.map { (key: CardValuesComposite<SwlDatabase.SwlID>.CardValue, value: String) in
					let id = key.id
					let idType: SwlDatabase.IDType
					if id.value.isEmpty || id == .zero || id == .null,
					   let newId = SwlDatabase.SwlID.new
					{
						idType = .new(newId)
					} else {
						idType = .existing(id)
					}
					return (idType, (value, key.templateFieldId))
				}),
				editedDescription: editedDescription,
				in: card.id)
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
					guard alert.runModal() == .alertFirstButtonReturn else { return false }
					lock(database: database)
					return true
				default:
					break
				}
			}
			showFailedToSaveAlert()
			return false
		}
		// Navigate to updated card.
		guard let cardIndex else {
			navigate(toDatabase: database, category: category)
			return true
		}
		navigate(toDatabase: database, category: category, index: cardIndex)
		return true
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

#if DEBUG
	/// A flag to control automatic unlock of the sample wallet used for development.
	static var didAutoUnlockSampleWallet = false
#endif

	// MARK: - File Loading

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

	// MARK: - Helper

	private func currentDatabaseAndCategory() -> (SwlDatabase, SwlDatabase.Category?)? {
		let database: SwlDatabase
		switch state {
		case .browseContent(let aDatabase),
		     .viewCard(let aDatabase):
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
}
