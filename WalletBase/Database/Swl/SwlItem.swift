//
//  SwlItem.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/26/21.
//

import Foundation

extension SwlDatabase {
	/// An item in the swl database.
	struct Item: ItemGridItem, Hashable {
		/// The decrypted name of the item.
		let name: String
		/// The type of the item.
		let itemType: ItemType

		/// The type of the item.
		var type: ItemGridItemType {
			switch itemType {
			case .category:
				return .category
			case .card:
				return .card
			}
		}

		internal init(name: String, type: ItemType) {
			self.name = name
			self.itemType = type
		}

		static func == (lhs: SwlDatabase.Item, rhs: SwlDatabase.Item) -> Bool {
			switch lhs.itemType {
			case .category(let lhsCategory):
				switch rhs.itemType {
				case .category(let rhsCategory):
					return lhsCategory.id == rhsCategory.id
				case .card:
					return false
				}
			case .card(let lhsCard):
				switch rhs.itemType {
				case .category:
					return false
				case .card(let rhsCard):
					return lhsCard.id == rhsCard.id
				}
			}
		}

		func hash(into hasher: inout Hasher) {
			type.hash(into: &hasher)

			switch itemType {
			case .category(let category):
				category.id.hash(into: &hasher)
			case .card(let card):
				card.id.hash(into: &hasher)
			}
		}

		enum ItemType {
			case category(category: Category)
			case card(card: Card)
		}
	}
}
