//
//  RandomizedCrypto.swift
//  WalletBase
//
//  Created by Mark Jerde on 3/9/23.
//

import Foundation

extension UInt32 {
	static var cryptographicRandomValue: Self? {
		// Thanks, Advanced Swift! https://www.advancedswift.com/secure-random-number-swift/#secure-random-int
		let count = MemoryLayout<Self>.size
		guard let bytes = [UInt8].cryptographicRandomBytes(count: count) else { return nil }

		// Convert bytes to Int
		let result = bytes.withUnsafeBytes { pointer in
			pointer.load(as: Self.self)
		}

		return result
	}
}

extension [UInt8] {
	static func cryptographicRandomBytes(count: Int) -> Self? {
		// Thanks, Advanced Swift! https://www.advancedswift.com/secure-random-number-swift/#secure-random-int
		var bytes = [UInt8](repeating: 0, count: count)

		// Fill bytes with secure random data
		let status = SecRandomCopyBytes(
			kSecRandomDefault,
			count,
			&bytes
		)

		// A status of errSecSuccess indicates success
		guard status == errSecSuccess else {
			return nil
		}

		return bytes
	}
}
