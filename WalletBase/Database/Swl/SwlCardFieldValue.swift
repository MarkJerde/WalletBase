//
//  SwlCardFieldValue.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/29/21.
//

import Foundation

extension SwlDatabase {
	/// An swl database card field value.
	struct CardFieldValue: SwlIdentifiable {
		/// The ID of this field value.
		let id: SwlID
		/// The card ID of this field value.
		let cardId: SwlID
		/// The template field ID of this field value.
		let templateFieldId: SwlID
		/// The encrypted name of this card.
		let value: [UInt8]
	}
}
