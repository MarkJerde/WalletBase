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
		case browseContent(database: SwlDatabase, category: SwlDatabase.Item?)
		indirect case error(message: String, then: MyState)
	}

	@State private var state: MyState = .loadingDatabase
	@State private var category: SwlDatabase.Item?
	@State private var items: [SwlDatabase.Item] = []

	fileprivate func navigate(toCategory item: SwlDatabase.Item?, database: SwlDatabase) {
		category = item
		var swlCategory: SwlDatabase.Category?
		if let item = item,
		   case .category(let category) = item.itemType
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
		items = categories + cards
		state = .browseContent(database: database, category: item)
	}

	var body: some View {
		switch state {
		case .loadingDatabase:
			Text("Loading...")
				.onAppear {
					self.loadFile()
				}
		case .buttonToUnlock(let databaseFile):
			VStack {
				Text("Selected: \(databaseFile)")
				Button("Unlock") {
					let database = SwlDatabase(file: databaseFile)
					state = .unlocking(database: database)
				}
			}
			.padding(.all, 20)
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

						navigate(toCategory: nil, database: database)
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
		case .browseContent(let database, _):
			VStack {
				ItemGrid(items: $items,
				         container: $category) { item in
					guard item.type == .category else {
						return
					}
					navigate(toCategory: item, database: database)
				} onBackTap: {
					guard let category = category,
					      case .category(let swlCategory) = category.itemType else { return }
					let parentId = swlCategory.parent
					let parent = database.categoryItem(forId: parentId)
					navigate(toCategory: parent, database: database)
				}
				Button("Lock") {
					items = []
					category = nil
					state = .buttonToUnlock(databaseFile: database.file)
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
		}
	}

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
