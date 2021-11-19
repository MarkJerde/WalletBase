//
//  SwlDatabase.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/10/21.
//

import Foundation

class SwlDatabase {
	let file: URL

	init(file: URL) {
		self.file = file
	}

	func open(password: (@escaping (String) -> Void) -> Void, completion: @escaping (Bool) -> Void) {
		let crypto = SwlCrypto()
		self.crypto = crypto
		crypto.unlock(password: password, completion: completion)
	}

	func close() {
		crypto = nil
	}

	func test() -> String? {
		guard let crypto = crypto else { return nil }
		let bytes: [UInt8] = [0x06, 0x00, 0x00, 0x00, 0xF0, 0x64, 0x98, 0xC8, 0x2F, 0xFE, 0x9B, 0x03, 0xC0, 0xD1, 0xC7, 0x4C, 0xEE, 0x9B, 0x7B, 0x7E, 0x7A, 0x69, 0x22, 0xD7, 0xCC, 0x23, 0x9A, 0xCF, 0x06, 0xF9, 0x45, 0xF1, 0x82, 0xB2, 0xB5, 0x53]
		let data = Data(bytes)
		guard let plaintext = crypto.decryptString(data: data) else { return nil }
		return plaintext
	}

	private var crypto: CryptoProvider?
}
