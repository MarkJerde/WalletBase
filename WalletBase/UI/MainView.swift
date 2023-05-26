//
//  MainView.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/10/21.
//

import SwiftUI

struct MainView: View {
	private enum MyState {
		case loadingDatabase
		case buttonToUnlock(databaseFile: URL)
		case unlocking(database: SwlDatabase)
		case passwordPrompt(database: SwlDatabase, completion: (String) -> Void)
		case browseContent(database: SwlDatabase)
		case viewCard(database: SwlDatabase)
		indirect case error(message: String, then: MyState)
	}

	@State private var state: MyState = .loadingDatabase {
		didSet {
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

	struct Prompt {
		let title: String?
		let message: String?
		let options: [MenuView.Option]
		let handler: (String, [String: String]) -> Void
	}

	@State private var prompt: Prompt? = nil

	private func newFolderOrCardPrompt(in database: SwlDatabase, category: SwlDatabase.Category?) -> Prompt {
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
			let prompt: String
			let fieldName: String
			let isNewFolder = response == CreateNew.folder.rawValue.capitalized
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
		} cancel: {
			prompt = nil
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

	@State private var folder: WalletFile?
	@State private var files: [WalletFile] = []
	@State private var category: SwlDatabase.Item?
	@State private var items: [SwlDatabase.Item] = []
	@State private var card: CardValuesComposite<SwlDatabase.SwlID>?
	@State private var cardIndex: Int?
	@State private var numCards: Int?

	@State private var restoreCategoryId: SwlDatabase.SwlID?
	@State private var restoreCardId: SwlDatabase.SwlID?

	private func navigate(toDatabase database: SwlDatabase, category: SwlDatabase.Item? = nil, card: SwlDatabase.Card? = nil) {
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

	private func mostCommonTemplateID(in database: SwlDatabase) -> SwlDatabase.SwlID? {
		guard let cards: [SwlDatabase.Card] = try? database.database.select().compactMap({ $0 }) else {
			return nil
		}
		let templateIDs = cards.map { $0.templateID }
		let countedSet = NSCountedSet(array: templateIDs)
		let mostFrequent = countedSet.max { countedSet.count(for: $0) < countedSet.count(for: $1) }
		return mostFrequent as? SwlDatabase.SwlID
	}

	private func mostCommonIconID(in database: SwlDatabase) -> SwlDatabase.SwlID? {
		guard let cards: [SwlDatabase.Card] = try? database.database.select().compactMap({ $0 }) else {
			return nil
		}
		let templateIDs = cards.map { $0.iconID }
		let countedSet = NSCountedSet(array: templateIDs)
		let mostFrequent = countedSet.max { countedSet.count(for: $0) < countedSet.count(for: $1) }
		return mostFrequent as? SwlDatabase.SwlID
	}

	private func createCard(named: String, in database: SwlDatabase, category: SwlDatabase.Category) {
		// FIXME: Need a template ID.
		guard let templateID = mostCommonTemplateID(in: database),
		      // FIXME: Need an iconID. Just pick the most common.
		      let iconID = mostCommonIconID(in: database)
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
					folder = nil
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

	private func showFailedToSaveAlert() {
		let alert = NSAlert()
		alert.messageText = "Save Failed"
		alert.informativeText = "Something went wrong while trying to save. Please try again."
		alert.alertStyle = .warning
		alert.addButton(withTitle: "OK")
		_ = alert.runModal()
	}

	private func lock(database: SwlDatabase) {
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

	var body: some View {
		ZStack {
			Group {
				switch state {
				case .loadingDatabase:
					SandboxFileBrowser(folder: $folder,
					                   files: $files) { item in
						self.state = .buttonToUnlock(databaseFile: item.url)
					} browse: {
						self.loadFile()
					}
				case .buttonToUnlock(let databaseFile):
					UnlockView(file: "\(databaseFile)", unlock: {
						let database = SwlDatabase(file: databaseFile)
						state = .unlocking(database: database)
					}, importFile: FileStorage.contains(databaseFile) ? nil : {
						guard let importedFile = FileStorage.importFile(at: databaseFile) else { return }
						state = .buttonToUnlock(databaseFile: importedFile)
					})
				case .unlocking(let database):
					Text("Unlocking...")
						.onAppear {
							database.open { completion in
								state = .passwordPrompt(database: database, completion: completion)
							} completion: { success in
								guard success else {
									state = .error(message: "Unable to open database",
									               then: .buttonToUnlock(databaseFile: database.file))
									return
								}

								navigate(toDatabase: database)
							}
						}
				case .passwordPrompt(let database, let completion):
					PasswordPrompt { password in
						guard let password = password else {
							state = .error(message: "No password",
							               then: .buttonToUnlock(databaseFile: database.file))
							return
						}
						completion(password)
					}
#if DEBUG
						.onAppear {
							guard database.file.lastPathComponent == "Sample.swl",
							      !Self.didAutoUnlockSampleWallet else { return }
							Self.didAutoUnlockSampleWallet = true
							DispatchQueue.main.async {
								completion("WalletBase")
							}
						}
#endif
				case .browseContent(let database):
					VStack {
						ItemGrid(items: $items,
						         container: $category,
						         onItemTap: { item in
						         	switch item.itemType {
						         	case .card(let card):
						         		navigate(toDatabase: database, category: category, card: card)
						         	case .category:
						         		navigate(toDatabase: database, category: item)
						         	}
						         },
						         onBackTap: {
						         	guard let category = category,
						         	      case .category(let swlCategory) = category.itemType else { return }
						         	let parentId = swlCategory.parent
						         	let parent = database.categoryItem(forId: parentId)
						         	// Clear the restore category so it won't try to keep restoring if we navigate back to the root.
						         	restoreCategoryId = nil
						         	navigate(toDatabase: database, category: parent)
						         },
						         onNewTap: {
						         	let createInCategory: SwlDatabase.Category?
						         	if let category = category,
						         	   case .category(let swlCategory) = category.itemType
						         	{
						         		createInCategory = swlCategory
						         	} else {
						         		createInCategory = nil
						         	}
						         	prompt = newFolderOrCardPrompt(in: database, category: createInCategory)
						         },
						         onSearch: (self.category == nil ? { searchString in
						         	guard !searchString.isEmpty else {
						         		items = items(of: category, in: database)
						         		return
						         	}
						         	items = items(of: searchString, in: database)
						         	numCards = nil
						         	cardIndex = nil
						         	state = .browseContent(database: database)
						         } : nil))
						Button("Lock") {
							lock(database: database)
						}
						.padding(.all, 20)
					}
				case .viewCard(let database):
					VStack {
						CardView(item: $card, onBackTap: {
							navigate(toDatabase: database, category: category)
						}, onPreviousTap: cardIndex == nil || cardIndex! <= 0 ? nil : {
							guard let cardIndex = cardIndex else {
								return
							}

							navigate(toDatabase: database, category: category, index: cardIndex - 1)
						}, onNextTap: cardIndex == nil || numCards == nil || cardIndex! + 1 >= numCards! ? nil : {
							guard let cardIndex = cardIndex else {
								return
							}

							navigate(toDatabase: database, category: category, index: cardIndex + 1)
						}, onSave: { edits, editedDescription in
							guard let card = card else {
								showFailedToSaveAlert()
								return false
							}
							do {
								try database.update(
									fieldValues: Dictionary(uniqueKeysWithValues: edits.map { (key: CardValuesComposite<SwlDatabase.SwlID>.CardValue, value: String) in
										let id = key.id
										let idType: SwlDatabase.IDType
										if id.value.isEmpty,
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
										folder = nil
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
							guard let cardIndex = cardIndex else {
								navigate(toDatabase: database, category: category)
								return true
							}
							navigate(toDatabase: database, category: category, index: cardIndex)
							return true
						})
						Button("Lock") {
							lock(database: database)
						}
						.padding(.all, 20)
					}
				case .error(let message, let then):
					VStack {
						Text("Error:")
						Text(message)
						Button("Ok") {
							state = then
						}
					}
					.compatibilityKeyboardShortcut(.defaultAction) { window in
						guard let firstSubviews = (window.contentViewController?.view ?? window.contentView)?.subviews,
						      let secondSubviews = firstSubviews.prefix(3).last?.subviews,
						      let button = secondSubviews.first as? NSButton else { return nil }
						return button
					}
				}
			}
			.blur(radius: prompt == nil ? 0 : 5)

			if let prompt {
				MenuView(title: prompt.title,
				         message: prompt.message,
				         options: prompt.options,
				         handler: prompt.handler)
					.backgroundColor(.blue)
					.foregroundColor(.white)
					.fixedSize()
			}
		}
	}

#if DEBUG
	static var didAutoUnlockSampleWallet = false
#endif

	private func loadFile() {
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

struct InitialView_Previews: PreviewProvider {
	static var previews: some View {
		MainView()
	}
}
