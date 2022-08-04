//
//  SwlCard+SQLiteQueryReadWritable.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.Card: SQLiteQueryReadWritable {
	enum Column: String {
		case id
		case name
		case description
		case cardViewID
		case hasOwnCardView
		case templateID
		case parentCategoryID
		case iconID
		case hitCount
		case syncID
		case createSyncID
	}

	static let columns: [Column] = [.id, .name, .description, .cardViewID, .hasOwnCardView, .templateID, .parentCategoryID, .iconID, .hitCount, .syncID, .createSyncID]
	static let table = SwlDatabase.Tables.cards
	static let primary: Column = .id
	func encode() -> [Column: SQLiteDataType] {
		[
			.id: id.encoded,
			.name: .blob(value: .init(arrayValue: name)),
			.description: .nullableBlob(value: nil),
			.cardViewID: cardViewID.encoded,
			.hasOwnCardView: .integer(value: 0), // (default: 0)
			.templateID: templateID.encoded,
			.parentCategoryID: parent.encoded,
			.iconID: iconID.encoded,
			.hitCount: .integer(value: 0), // (default: 0)
			.syncID: .integer(value: -1), // (default: -1)
			.createSyncID: .integer(value: -1), // (default: -1)
		]
	}
}
