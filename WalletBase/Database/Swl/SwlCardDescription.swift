//
//  SwlCardDescription.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/18/21.
//

import Foundation

extension SwlDatabase {
	/// An swl database card description.
	struct CardDescription {
		/// The ID of this card.
		let id: SwlID
		/// The encrypted description of this card.
		let description: [UInt8]?
	}
}
