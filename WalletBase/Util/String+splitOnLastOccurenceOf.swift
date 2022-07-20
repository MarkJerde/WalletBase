//
//  String+splitOnLastOccurenceOf.swift
//  WalletBase
//
//  Created by Mark Jerde on 7/19/22.
//

import Foundation

extension String {
	func splitOnLastOccurence(of separator: String) -> (String, String)? {
		guard let theRange = range(of: separator, options: .backwards) else {
			return nil
		}

		let before = String(self[..<theRange.lowerBound])
		let after = String(self[theRange.upperBound...])
		return (before, after)
	}
}
