//
//  SwlDatabaseVersion.swift
//  WalletBase
//
//  Created by Mark Jerde on 8/23/23.
//

import Foundation

extension SwlDatabase {
	/// The swl database version record.
	struct DatabaseVersion: Equatable {
		/// The ID of this product.
		let productID: Int32
		/// The name of this product.
		let productName: String
		/// The version of this product.
		let versionString: String
		/// The compatibility version of this product.
		let compatibilityVersion: Int32
		/// The major version of this product.
		let productMajorVersion: Int32
		/// The minor version of this product.
		let productMinorVersion: Int32
	}
}
