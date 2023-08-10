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
		/// Something, data but it doesn't appear to be encrypted. Example is an alternating "xx MMMMMM" "xx NNNNNN" pattern where the MMMMMM and NNNNNN are two six digit hex numbers and each xx is a somewhat random two digit hex number. The xx values seem somewhat zoned, moreso in the 2nd, 4th, 6th, etc xx values, and can contain repeats. There are twelve x-M-x-N sets followed by one final x-M.
		let syncInfo: [UInt8]?
		/// Something. Starts at -1.
		let createSyncID: Int32
	}
}
