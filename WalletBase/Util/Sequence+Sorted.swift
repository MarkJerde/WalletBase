//
//  Sequence+Sorted.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/26/21.
//

import Foundation

// Thanks, Sundell! https://www.swiftbysundell.com/articles/the-power-of-key-paths-in-swift/
extension Sequence {
	func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
		return sorted { a, b in
			a[keyPath: keyPath] < b[keyPath: keyPath]
		}
	}
}
