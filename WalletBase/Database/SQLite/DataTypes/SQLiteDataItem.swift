//
//  SQLiteDataItem.swift
//  WalletBase
//
//  Created by Mark Jerde on 8/2/22.
//

import Foundation

struct SQLiteDataItem: Equatable {
	init(dataValue: Data) {
		self.dataValue = dataValue
		self.arrayValue = nil
		self.blobValue = nil
	}

	init(arrayValue: [UInt8]) {
		self.dataValue = nil
		self.arrayValue = arrayValue
		self.blobValue = nil
	}

	init(blobValue: String) {
		self.dataValue = nil
		self.arrayValue = nil
		self.blobValue = blobValue
	}

	private let dataValue: Data?
	private let arrayValue: [UInt8]?
	private let blobValue: String?

	var asBlob: String {
		if let blobValue = blobValue {
			return blobValue
		}

		return "x'\(asArray.map { String(format: "%02X", $0) }.joined())'"
	}

	var asArray: [UInt8] {
		if let arrayValue = arrayValue {
			return arrayValue
		}
		if let dataValue = dataValue {
			return [UInt8](dataValue)
		}
		if var blobValue = blobValue {
			blobValue.removeFirst(2) // "X'"
			blobValue.removeLast(1) // "'"
			return blobValue.split(by: 2).map { UInt8($0, radix: 16) ?? 0 } // Map defects to zero.
		}
		return []
	}

	var asData: Data {
		if let dataValue = dataValue {
			return dataValue
		}
		return Data(asArray)
	}
}
