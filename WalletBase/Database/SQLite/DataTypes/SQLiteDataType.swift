//
//  SQLiteDataType.swift
//  WalletBase
//
//  Created by Mark Jerde on 8/2/22.
//

import Foundation

enum SQLiteDataType: Equatable {
	case integer(value: Int32)
	case varchar(value: SQLiteVarcharItem)
	case blob(value: SQLiteDataItem)
	case nullableVarchar(value: SQLiteVarcharItem?)
	case nullableBlob(value: SQLiteDataItem?)

	var queryValue: String {
		switch self {
		case .integer(let value):
			return "\(value)"
		case .varchar(let value):
			return value.queryEncoded
		case .blob(let value):
			return value.asBlob
		case .nullableVarchar(let value):
			return value?.queryEncoded ?? "NULL"
		case .nullableBlob(let value):
			return value?.asBlob ?? "NULL"
		}
	}

	static func == (lhs: SQLiteDataType, rhs: SQLiteDataType) -> Bool {
		switch lhs {
		case .integer(let lhsValue):
			switch rhs {
			case .integer(let rhsValue):
				return lhsValue == rhsValue
			default:
				return false
			}
		case .varchar(let lhsValue):
			switch rhs {
			case .varchar(let rhsValue):
				return lhsValue == rhsValue
			default:
				return false
			}
		case .blob(let lhsValue):
			switch rhs {
			case .blob(let rhsValue):
				return lhsValue == rhsValue
			default:
				return false
			}
		case .nullableVarchar(let lhsValue):
			switch rhs {
			case .nullableVarchar(let rhsValue):
				return lhsValue == rhsValue
			default:
				return false
			}
		case .nullableBlob(let lhsValue):
			switch rhs {
			case .nullableBlob(let rhsValue):
				return lhsValue == rhsValue
			default:
				return false
			}
		}
	}
}
