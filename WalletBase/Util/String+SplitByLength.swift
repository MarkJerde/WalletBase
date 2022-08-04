//
//  String+SplitByLength.swift
//  WalletBase
//
//  Created by Mark Jerde on 8/2/22.
//

import Foundation

extension String {
	func split(by length: Int) -> [String] {
		// Thanks, Stack Overflow! https://stackoverflow.com/a/38980231
		var startIndex = startIndex
		var results = [Substring]()

		while startIndex < endIndex {
			let endIndex = index(startIndex, offsetBy: length, limitedBy: endIndex) ?? endIndex
			results.append(self[startIndex ..< endIndex])
			startIndex = endIndex
		}

		return results.map { String($0) }
	}
}
