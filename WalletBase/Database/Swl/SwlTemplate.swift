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
		/*
		 CREATE TABLE IF NOT EXISTS "spbwlt_Template" (^M
		 "ID" VARCHAR(22)  UNIQUE NOT NULL PRIMARY KEY,^M
		 "Name" BLOB  NOT NULL,^M
		 "Description" BLOB NULL,^M
		 "CardViewID" VARCHAR(22)  NOT NULL,^M
		 "SyncID" INTEGER NOT NULL DEFAULT -1,^M
		 "CreateSyncID" INTEGER NOT NULL DEFAULT -1^M
		 );
		 */

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
