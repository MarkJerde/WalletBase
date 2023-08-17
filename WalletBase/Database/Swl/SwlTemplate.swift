//
//  SwlTemplate.swift
//  WalletBase
//
//  Created by Mark Jerde on 2/23/23.
//

import Foundation

extension SwlDatabase {
	/// An swl database card template.
	struct Template {
		/// The ID of this template.
		let id: SwlID
		/// The encrypted name of this template.
		let name: [UInt8]
		/// The encrypted description of this template.
		let description: [UInt8]?
		/// The card view ID of this template.
		let cardViewID: SwlID
		/// Something
		let syncID: Int32
		/// Something
		let createSyncID: Int32
	}
}
