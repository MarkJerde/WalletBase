//
//  SwlCategory.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/26/21.
//

import Foundation

extension SwlDatabase {
	/// An swl database category.
	///
	/// Categories may contain other categories, cards, or both.
	struct Category {
		/// The ID of this category.
		let id: SwlID
		/// The encrypted name of this category.
		let name: [UInt8]
		/// The ID of the parent of this category.
		let parent: SwlID
	}
}
