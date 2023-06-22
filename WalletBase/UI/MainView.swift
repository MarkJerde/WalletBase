//
//  MainView.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/10/21.
//

import SwiftUI

struct MainView: View {
	@ObservedObject var appState: AppState

	@State private var folder: WalletFile?
	@State private var files: [WalletFile] = []
	@State private var previousSearch: String?

	var body: some View {
		ZStack {
			Group {
				switch appState.state {
				case .loadingDatabase:
					SandboxFileBrowser(folder: $folder,
					                   files: $files) { item in
						self.appState.state = .buttonToUnlock(databaseFile: item.url)
					} browse: {
						self.appState.loadFile()
					}
				case .buttonToUnlock(let databaseFile):
					UnlockView(file: "\(databaseFile)", unlock: {
						let database = SwlDatabase(file: databaseFile)
						appState.state = .unlocking(database: database)
					}, importFile: FileStorage.contains(databaseFile) ? nil : {
						guard let importedFile = FileStorage.importFile(at: databaseFile) else { return }
						appState.state = .buttonToUnlock(databaseFile: importedFile)
					}, pickOther: {
						appState.state = .loadingDatabase
					})
				case .unlocking(let database):
					Text("Unlocking...")
						.onAppear {
							database.open { completion in
								appState.state = .passwordPrompt(database: database, completion: completion)
							} completion: { success in
								guard success else {
									appState.state = .error(message: "Unable to open database",
									                        then: .buttonToUnlock(databaseFile: database.file))
									return
								}

								appState.navigate(toDatabase: database)
							}
						}
				case .passwordPrompt(let database, let completion):
					PasswordPrompt { password in
						guard let password = password else {
							appState.state = .error(message: "No password",
							                        then: .buttonToUnlock(databaseFile: database.file))
							return
						}
						completion(password)
					}
#if DEBUG
						.onAppear {
							guard database.file.lastPathComponent == "Sample.swl",
							      !AppState.didAutoUnlockSampleWallet else { return }
							AppState.didAutoUnlockSampleWallet = true
							DispatchQueue.main.async {
								completion("WalletBase")
							}
						}
#endif
				case .browseContent(let database):
					VStack {
						ItemGrid(items: appState.items,
						         container: appState.category,
						         onItemTap: { item in
						         	switch item.itemType {
						         	case .card(let card):
						         		self.appState.navigate(toDatabase: database, category: self.appState.category, card: card)
						         	case .category:
						         		self.appState.navigate(toDatabase: database, category: item)
						         	}
						         },
						         onBackTap: {
						         	guard let category = self.appState.category,
						         	      case .category(let swlCategory) = category.itemType else { return }
						         	let parentId = swlCategory.parent
						         	let parent = database.categoryItem(forId: parentId)
						         	// Clear the restore category so it won't try to keep restoring if we navigate back to the root.
						         	self.appState.restoreCategoryId = nil
						         	self.appState.navigate(toDatabase: database, category: parent)
						         },
						         onNewTap: {
						         	appState.shouldPresentCreateSheet = true
						         },
						         onSearch: (self.appState.category == nil ? { searchString in
						         	guard searchString != previousSearch else { return }
						         	previousSearch = searchString
						         	guard !searchString.isEmpty else {
						         		self.appState.items = self.appState.items(of: self.appState.category, in: database)
						         		return
						         	}
						         	self.appState.items = appState.items(of: searchString, in: database)
						         	self.appState.numCards = nil
						         	self.appState.cardIndex = nil
						         	self.appState.state = .browseContent(database: database)
						         } : nil))
						Button("Lock") {
							self.appState.lock(database: database)
						}
						.padding(.all, 20)
					}
					.sheet(isPresented: $appState.shouldPresentCreateSheet) {
						// No-op. Called on dismiss.
					} content: {
						NewItemView(types: appState.currentCreatableTypes,
						            availableTemplates: []) { itemToCreate, name in
							switch itemToCreate {
							case .folder:
								appState.createFolder(named: name)
							case .card:
								appState.createCard(named: name)
							}
							// Navigate to reload the content.
							appState.navigate(toDatabase: database, category: appState.category, card: nil)
							appState.shouldPresentCreateSheet = false
							// If the sheet is presented from the Menu, then the available create types were overridden to match the specific menu item selected, so we need to reset the menu enables as they also set the sheet options.
							appState.setMenuEnables()
						} cancel: {
							appState.shouldPresentCreateSheet = false
							// If the sheet is presented from the Menu, then the available create types were overridden to match the specific menu item selected, so we need to reset the menu enables as they also set the sheet options.
							appState.setMenuEnables()
						}
						.padding()
						.frame(minWidth: 400)
					}
				case .viewCard(let database):
					VStack {
						CardView(item: $appState.card, onBackTap: {
							appState.navigate(toDatabase: database, category: appState.category)
						}, onPreviousTap: appState.cardIndex == nil || appState.cardIndex! <= 0 ? nil : {
							guard let cardIndex = appState.cardIndex else {
								return
							}

							appState.navigate(toDatabase: database, category: appState.category, index: cardIndex - 1)
						}, onNextTap: appState.cardIndex == nil || appState.numCards == nil || appState.cardIndex! + 1 >= appState.numCards! ? nil : {
							guard let cardIndex = appState.cardIndex else {
								return
							}

							appState.navigate(toDatabase: database, category: appState.category, index: cardIndex + 1)
						}, onSave: { edits, editedDescription in
							guard let card = appState.card else {
								appState.showFailedToSaveAlert()
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
										appState.lock(database: database)
										return true
									default:
										break
									}
								}
								appState.showFailedToSaveAlert()
								return false
							}
							// Navigate to updated card.
							guard let cardIndex = appState.cardIndex else {
								appState.navigate(toDatabase: database, category: appState.category)
								return true
							}
							appState.navigate(toDatabase: database, category: appState.category, index: cardIndex)
							return true
						})
						Button("Lock") {
							appState.lock(database: database)
						}
						.padding(.all, 20)
					}
				case .error(let message, let then):
					VStack {
						Text("Error:")
						Text(message)
						Button("Ok") {
							appState.state = then
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
		}
	}
}

struct InitialView_Previews: PreviewProvider {
	static var previews: some View {
		MainView(appState: .init())
	}
}
