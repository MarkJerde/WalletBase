//
//  SQLiteVarcharItem.swift
//  WalletBase
//
//  Created by Mark Jerde on 8/2/22.
//

import Foundation

struct SQLiteVarcharItem: Equatable {
	init(arrayValue: [UInt8]) {
		self.arrayValue = arrayValue
		self.stringValue = nil
	}

	init(stringValue: String) {
		self.arrayValue = nil
		self.stringValue = stringValue
	}

	private let arrayValue: [UInt8]?
	private let stringValue: String?

	var count: Int {
		arrayValue?.count ?? stringValue?.count ?? 0
	}

	var queryEncoded: String {
		if let stringValue = stringValue {
			return "'\(stringValue.replacingOccurrences(of: "'", with: "''"))'"
		}
		if let arrayValue = arrayValue {
			return "cast(\(SQLiteDataItem(arrayValue: arrayValue).asBlob) as text)"
		}
		return ""
	}
}
