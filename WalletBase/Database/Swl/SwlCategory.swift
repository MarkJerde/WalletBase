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
	struct Category: SwlIdentifiable {
		/// The ID of this category.
		let id: SwlID
		/// The encrypted name of this category.
		let name: [UInt8]
		/// The encrypted description of this category.
		let description: [UInt8]?
		/// The ID of the icon of this category.
		let iconID: SwlID
		/// The ID of the default template of this category.
		let defaultTemplateID: SwlID
		/// The ID of the parent of this category.
		let parent: SwlID
		/// Something. Starts at -1.
		let syncID: Int32
		/// Something. Starts at -1.
		let createSyncID: Int32
	}
}
