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

		/// Children of the root category have an empty string for their ID.
		var rootCategory: Self { .init(value: []) }
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

	/// The SQL query condition which can be used to find all records which might match this ID. Any use of this should be followed up by a call to `filter(results:,)` to remove false matches. The caller must provide the LValue of this condition.
	///
	/// The result will be a `like` statement with an RValue of concatenated `char()` statements, one for each byte of this ID. Values which SQL treats as special and values above the ability for SQL to handle will be converted to `'_'`, and consecutive such values will be joined as `'%'`. The possibility of `'%'` matching zero characters seems an odd choice, but testing thus far has indicated this is favorable to the odd results of just using `'_'`.
	var queryCondition: String {
		var accumulator: [String] = []
		var previous = ""

		// Iterate over our bytes.
		for value in value {
			let current: String?

			// Evalute this byte.
			if value < 128, value != 37, value != 123 {
				// Make okay values concretely.
				current = "char(\(value))"
			} else {
				// Map values SQL won't match exactly to wildcards.
				if previous == "'_'" {
					// It would be two consecutive undercores, so convert to a single percent.
					accumulator.removeLast()
					current = "'%'"
				} else if previous == "'%'" {
					// Already following a percent so ignore this byte.
					current = nil
				} else {
					// Use an underscore since we are following an okay value or are at the start.
					current = "'_'"
				}
			}

			// If we have something, append it.
			if let current = current {
				accumulator.append(current)
				previous = current
			}
		}

		// Form the condition.
		return "like \(accumulator.isEmpty ? "''" : accumulator.joined(separator: "||"))"
	}

	/// Filters an array, returning only those for which the given transformation returns a value equal to this ID.
	/// - Parameters:
	///   - results: The array to filter.
	///   - transform: A mapping closure. transform accepts an element of this sequence as its parameter and returns an SwlID.
	/// - Returns: An array containing the filtered elements of the provided array.
	func filter<T>(results: [T], _ transform: (T) -> Self) -> [T] {
		return results.filter { transform($0) == self }
	}
}
