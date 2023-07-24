//
//  MainView.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/10/21.
//

import SwiftUI

struct MainView: View {
	@ObservedObject var appState: AppState

	var body: some View {
		ZStack {
			Group {
				switch appState.state {
				case .loadingDatabase:
					SandboxFileBrowser { item in
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

								guard !appState.restoreNavigation(inDatabase: database) else {
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
						         	self.appState.navigate(toDatabase: database, category: parent)
						         },
						         onNewTap: {
						         	appState.shouldPresentCreateSheet = true
						         },
						         onSearch: (self.appState.category == nil ? { searchString in
						         	appState.search(searchString: searchString)
						         } : nil),
						         onItemCut: { item in
						         	self.appState.cut(item: item)
						         },
						         onPaste: appState.canPaste ? {
						         	let errorText = self.appState.paste()
						         	guard let errorText else {
						         		// Navigate to reload the content.
						         		appState.navigate(toDatabase: database, category: appState.category, card: nil)
						         		return
						         	}
						         	Alert.pasteFailed(errorText: errorText).show()
						         } : nil,
						         onItemRename: { _ in
						         	// TODO: Show a rename sheet.
						         },
						         onItemDelete: { item in

						         	let itemType: String
						         	switch item.type {
						         	case .file:
						         		itemType = "Wallet"
						         	case .category:
						         		itemType = "Folder"
						         	case .card:
						         		itemType = "Card"
						         	}

						         	Alert.delete(type: itemType, name: item.name).show { response in
						         		guard response == "Yes" else { return }

						         		switch item.itemType {
						         		case .category(let category):
						         			self.appState.delete(category: category)
						         		case .card(let card):
						         			self.appState.delete(card: card)
						         		}

						         		// Navigate to reload the content.
						         		appState.navigate(toDatabase: database, category: appState.category, card: nil)
						         	}
						         })
						Button("Lock") {
							self.appState.lock(database: database)
						}
						.padding(.all, 20)
					}
					.sheet(isPresented: $appState.shouldPresentCreateSheet) {
						// No-op. Called on dismiss.
					} content: {
						NewItemView(types: appState.currentCreatableTypes) { itemType in
							appState.getAvailableTemplates(itemType: itemType)
						} create: { itemToCreate, name, templateID in
							switch itemToCreate {
							case .folder:
								appState.createFolder(named: name, defaultTemplateID: templateID)
							case .card:
								appState.createCard(named: name, templateID: templateID)
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
							appState.navigateToPrevious()
						}, onNextTap: appState.cardIndex == nil || appState.numCards == nil || appState.cardIndex! + 1 >= appState.numCards! ? nil : {
							appState.navigateToNext()
						}, onSave: { edits, editedDescription in
							appState.save(edits: edits, editedDescription: editedDescription)
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
