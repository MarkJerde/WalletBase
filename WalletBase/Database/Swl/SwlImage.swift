//
//  SwlImage.swift
//  WalletBase
//
//  Created by Mark Jerde on 8/22/23.
//

import Foundation

extension SwlDatabase {
	/// An swl database card.
	struct Image: Equatable, SwlIdentifiable {
		/// The ID of this image.
		let id: SwlID
		/// The encrypted name of this image.
		let name: [UInt8]
		/// The data of this image.
		let data: [UInt8]?
		/// Something. Starts at -1.
		let syncID: Int32
		/// Something. Starts at -1.
		let createSyncID: Int32
	}
}
