//
//  SwlID.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/26/21.
//

import Foundation

extension SwlDatabase {
	/// An identifier for swl databases.
	///
	/// The swl database uses a VARCHAR as ID containing the raw bytes of a UInt64. Since SQL doesn't support 64-bit integers and doesn't well support CHAR values above ASCII (0x7f) this gets to be a complicated mess.
	///
	/// This struct and its extensions provide storage of swl IDs, conversion to UInt64, conversion to SQL query conditions which will match this ID (and possibly other IDs since SQL doesn't well support CHAR values above ASCII), and filtering to remove the false matches.
	struct SwlID: Equatable, Hashable {
		let value: [UInt8]
		let hexString: String

		/// Children of the root category have an empty string for their ID.
		static var rootCategory: Self { .init(value: [], hexString: "") }

		var encoded: SQLiteDataType {
			.varchar(value: .init(arrayValue: value))
		}

		static var new: Self? {
			guard let value = [UInt8].cryptographicRandomBytes(count: 8) else { return nil }

			return Self(value: value, hexString: value.map { String(format: "%02X", $0) }.joined())
		}

		static var zero: Self {
			Self(value: [0], hexString: "0x0")
		}

		/// Provide the next ID. Only valid if starting from .zero.
		var next: Self {
			let newValue = (value.last ?? 0) + 1
			return Self(value: [newValue], hexString: String(format: "%02X", newValue))
		}
	}
}

extension SwlDatabase.SwlID {
	var asUInt64: UInt64 {
		var accumulator: UInt64 = 0
		for (index, value) in value.enumerated() {
			accumulator += UInt64(value) << (index * 8)
		}
		return accumulator
	}

	/// The SQL query condition which can be used to find all records which might match this ID.
	var queryCondition: String {
		// Ideally, something like:
		// "select hex(id) from spbwlt_Card where ParentCategoryID is cast(x\'0123456789ABCDEF\' as text)"
		// or
		// "select hex(id) from spbwlt_Card where hex(ParentCategoryID) is \'02CA9A4D203C4F44\'".
		// It also sort of works to use:
		// "select hex(id) from spbwlt_Card where hex(ParentCategoryID) like char(2)||\'%\'||char(33)||char(81)||char(29)||char(50)||char(61)"
		// but that requires filtering afterward because it might match multiple different IDs due to the wildcard.
		"is cast(x'\(hexString)' as text)"
	}
}
