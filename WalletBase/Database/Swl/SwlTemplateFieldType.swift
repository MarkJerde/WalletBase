//
//  SwlTemplateFieldType.swift
//  WalletBase
//
//  Created by Mark Jerde on 8/22/23.
//

import Foundation

extension SwlDatabase {
	/// An swl database card.
	struct TemplateFieldType: Equatable {
		/// The ID of this field type.
		let id: Int32
		/// The name of this field type.
		let name: String
		/// Something. Starts at -1.
		let syncID: Int32
		/// Something. Starts at -1.
		let createSyncID: Int32
	}
}
