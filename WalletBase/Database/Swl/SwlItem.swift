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
		var type: ItemGridItemType { .category }
		/// The category if the item type is category.
		let category: Category

		static func == (lhs: SwlDatabase.Item, rhs: SwlDatabase.Item) -> Bool {
			lhs.category.id == rhs.category.id
		}

		func hash(into hasher: inout Hasher) {
			category.id.hash(into: &hasher)
		}
	}
}
