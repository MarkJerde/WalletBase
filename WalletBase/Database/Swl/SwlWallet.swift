//
//  SwlWallet.swift
//  WalletBase
//
//  Created by Mark Jerde on 8/8/23.
//

import Foundation

extension SwlDatabase {
	/// An swl database card.
	struct Wallet: Equatable, SwlIdentifiable {
		/// The ID of this wallet.
		let id: SwlID
		/// Heck if I know. Observed values in the -400 millions and -800 millions.
		let advVersionInfo: Int32
		/// Something. Starts at -1.
		let currentSyncID: Int32
		/// Something. Starts at -1.
		let syncID: Int32
		/// Something, data but it doesn't appear to be encrypted.
		let syncInfo: [UInt8]?
		/// Something. Starts at -1.
		let createSyncID: Int32
	}
}
