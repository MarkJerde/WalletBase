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
	              onSearch: ((String) -> Void)? = nil)
	{
		self.items = items
		self.container = container
		self.emptyMessage = emptyMessage
		self.onItemTap = onItemTap
		self.onBackTap = onBackTap
		self.onNewTap = onNewTap
		self.onSearch = onSearch
	}

	var items: [Item]
	var container: Item?
	let emptyMessage: String?
	let onItemTap: (Item) -> Void
	let onBackTap: () -> Void
	let onNewTap: (() -> Void)?
	let onSearch: ((String) -> Void)?
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
					.frame(maxHeight: .infinity)
			} else {
				ScrollView {
					CompatibilityVGrid(data: items, id: \.self) { item in
						ItemGridItem(item: item, onItemTap: onItemTap)
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
	}
}
