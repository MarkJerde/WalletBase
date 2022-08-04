//
//  SwlCard.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/26/21.
//

import Foundation

extension SwlDatabase {
	/// An swl database card.
	struct Card: Equatable {
		/// The ID of this card.
		let id: SwlID
		/// The encrypted name of this card.
		let name: [UInt8]
		/// The encrypted description of this card.
		let description: [UInt8]?
		/// The ID of the view of this card.
		let cardViewID: SwlID
		/// Something
		let hasOwnCardView: Int32
		/// The ID of the template of this card.
		let templateID: SwlID
		/// The ID of the parent of this card.
		let parent: SwlID
		/// The ID of the icon of this card.
		let iconID: SwlID
		/// Something
		let hitCount: Int32
		/// Something
		let syncID: Int32
		/// Something
		let createSyncID: Int32
	}
}
