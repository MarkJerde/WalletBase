//
//  SwlCard.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/26/21.
//

import Foundation

extension SwlDatabase {
	/// An swl database card.
	struct Card {
		/// The ID of this card.
		let id: SwlID
		/// The encrypted name of this card.
		let name: [UInt8]
		/// The ID of the parent of this card.
		let parent: SwlID
	}
}
