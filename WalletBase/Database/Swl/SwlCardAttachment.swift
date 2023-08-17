//
//  SwlCardAttachment.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/10/21.
//

import Foundation

extension SwlDatabase {
	/// An swl database card attachment.
	struct CardAttachment: Equatable, Hashable {
		/// The ID of this attachment.
		let id: SwlID
		/// The card ID of this attachment.
		let cardId: SwlID
		/// The encrypted name of this attachment.
		let name: [UInt8]
		/// The encrypted data of this attachment.
		let data: [UInt8]
		/// Something. Starts at -1.
		let syncID: Int32
		/// Something. Starts at -1.
		let createSyncID: Int32
	}
}
