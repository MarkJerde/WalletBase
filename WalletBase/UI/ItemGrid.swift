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
}

extension ItemGridItemType {
	var icon: String {
		switch self {
		case .card:
			return "creditcard"
		case .category:
			return "folder"
		}
	}

	var color: Color {
		switch self {
		case .card:
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
	let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 5)
	@Binding var items: [Item]
	@Binding var container: Item?
	let onItemTap: (Item) -> Void
	let onBackTap: () -> Void
	var body: some View {
		NavigationFrame(currentName: container?.name,
		                onBackTap: onBackTap) {
			ScrollView {
				LazyVGrid(columns: columns, spacing: 20) {
					ForEach(items, id: \.self) { item in
						VStack {
							Image(systemName: item.type.icon)
								.font(.system(size: 30))
								.foregroundColor(item.type.color)
								.frame(width: 50, height: 50)
							Text(item.name)
						}
						.onTapGesture {
							onItemTap(item)
						}
					}
				}
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
		ItemGrid(items: .constant(items),
		         container: .constant(container)) {
			NSLog("tapped \($0)")
		} onBackTap: {
			NSLog("tapBack")
		}
	}
}
