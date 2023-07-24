//
//  ItemGrid.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/19/21.
//

import SwiftUI

enum ItemGridItemType {
	case card
	case category
	case file
}

extension ItemGridItemType {
	var icon: String {
		switch self {
		case .card:
			return "creditcard"
		case .category:
			return "folder"
		case .file:
			return "doc"
		}
	}

	var color: Color {
		switch self {
		case .card,
		     .file:
			return .green
		case .category:
			return .blue
		}
	}
}

protocol ItemGridItem: Hashable {
	var name: String { get }
	var type: ItemGridItemType { get }
}

struct ItemGrid<Item: ItemGridItem>: View {
	internal init(items: [Item],
	              container: Item?,
	              emptyMessage: String? = "Empty",
	              onItemTap: @escaping (Item) -> Void,
	              onBackTap: @escaping () -> Void,
	              onNewTap: (() -> Void)? = nil,
	              onSearch: ((String) -> Void)? = nil,
	              onItemCut: ((Item) -> Void)? = nil,
	              onPaste: (() -> Void)? = nil,
	              onItemRename: ((Item) -> Void)? = nil,
	              onItemDelete: ((Item) -> Void)? = nil)
	{
		self.items = items
		self.container = container
		self.emptyMessage = emptyMessage
		self.onItemTap = onItemTap
		self.onBackTap = onBackTap
		self.onNewTap = onNewTap
		self.onSearch = onSearch
		self.onItemCut = onItemCut
		self.onPaste = onPaste
		self.onItemRename = onItemRename
		self.onItemDelete = onItemDelete
	}

	var items: [Item]
	var container: Item?
	let emptyMessage: String?

	let onItemTap: (Item) -> Void
	let onBackTap: () -> Void
	let onNewTap: (() -> Void)?
	let onSearch: ((String) -> Void)?
	let onItemCut: ((Item) -> Void)?
	let onPaste: (() -> Void)?
	let onItemRename: ((Item) -> Void)?
	let onItemDelete: ((Item) -> Void)?

	var body: some View {
		NavigationFrame(currentName: container?.name,
		                onBackTap: onBackTap,
		                onNewTap: onNewTap,
		                onPreviousTap: nil,
		                onNextTap: nil,
		                onSearch: onSearch) {
			if items.isEmpty,
			   let emptyMessage = emptyMessage
			{
				Text(emptyMessage)
					.frame(maxWidth: .infinity, maxHeight: .infinity)
					.background(Color("ordinaryBackground"))
					.contextMenu {
						if let onPaste {
							Button(action: {
								onPaste()
							}) {
								if #available(macOS 11.0, *) {
									Image(systemName: "paintbrush")
								}
								Text("Paste")
							}
						}
					}
			} else {
				ScrollView {
					CompatibilityVGrid(data: items, id: \.self) { item in
						ItemGridItem(item: item, onItemTap: onItemTap)
							.contextMenu {
								if let onItemCut {
									Button(action: {
										onItemCut(item)
									}) {
										if #available(macOS 11.0, *) {
											Image(systemName: "scissors")
										}
										Text("Cut")
									}
								}
								if let onItemRename {
									Button(action: {
										onItemRename(item)
									}) {
										if #available(macOS 11.0, *) {
											Image(systemName: "pencil")
										}
										Text("Rename")
									}
								}
								if let onItemDelete {
									Button(action: {
										onItemDelete(item)
									}) {
										if #available(macOS 11.0, *) {
											Image(systemName: "trash")
										}
										Text("Delete")
									}
								}
							}
					}
				}
				.frame(maxHeight: .infinity)
				.contextMenu {
					if let onPaste {
						Button(action: {
							onPaste()
						}) {
							if #available(macOS 11.0, *) {
								Image(systemName: "paintbrush")
							}
							Text("Paste")
						}
					}
				}
			}
		}
	}

	private struct ItemGridItem: View {
		let item: Item
		let onItemTap: (Item) -> Void

		var body: some View {
			VStack {
				Image.image(systemName: item.type.icon,
				            color: item.type.color,
				            size: 30)
					.frame(width: 50, height: 50)
				Text(item.name)
				Spacer(minLength: 0)
			}
			.onTapGesture {
				onItemTap(item)
			}
		}
	}
}

struct ItemGrid_Previews_Item: ItemGridItem {
	let name: String
	let type: ItemGridItemType
}

struct ItemGrid_Previews: PreviewProvider {
	static let items: [ItemGrid_Previews_Item] = [
		.init(name: "Able", type: .category),
		.init(name: "Baker", type: .category),
		.init(name: "Charlie", type: .category),
		.init(name: "Kilo", type: .card),
		.init(name: "Alpha", type: .card),
		.init(name: "Tango", type: .card),
		.init(name: "Foxtrot", type: .card),
	]
	static let container: ItemGrid_Previews_Item? = ItemGrid_Previews_Item(name: "Zulu", type: .category)
	static var previews: some View {
		ItemGrid(items: items,
		         container: container) {
			NSLog("tapped \($0)")
		} onBackTap: {
			NSLog("tapBack")
		} onNewTap: {
			NSLog("tapNew")
		} onSearch: { searchString in
			NSLog("searching \(searchString)")
		}

		ItemGrid(items: [],
		         container: container) {
			NSLog("tapped \($0)")
		} onBackTap: {
			NSLog("tapBack")
		} onNewTap: {
			NSLog("tapNew")
		} onSearch: { searchString in
			NSLog("searching \(searchString)")
		}
	}
}
