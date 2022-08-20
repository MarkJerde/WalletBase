//
//  SwlCrypto.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/14/21.
//

import CommonCrypto
import Foundation

// Thanks, Stack Overflow! https://stackoverflow.com/a/25762128
extension String {
	func sha1() -> String {
		let data = Data(utf8)
		var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
		data.withUnsafeBytes {
			_ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
		}
		let hexBytes = digest.map { String(format: "%02hhx", $0) }
		return hexBytes.joined()
	}
}

class SwlCrypto: CryptoProvider {
	func unlock(password: (@escaping (String) -> Void) -> Void, completion: @escaping (Bool) -> Void) {
		password { password in
			let password = "\(password)\0" // .map { "\($0)\00" }.joined(separator: "")
			// let sha1 = password.sha1()

			// Adapted from https://stackoverflow.com/a/25762128
			guard let utf16leData = password.data(using: .utf16LittleEndian) else {
				completion(false)
				return
			}
			var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
			utf16leData.withUnsafeBytes {
				_ = CC_SHA1($0.baseAddress, CC_LONG(utf16leData.count), &digest)
			}
			// let hexBytes = digest.map { String(format: "%02hhx", $0) }
			// let sha1 = hexBytes.joined()

			var keyArray = Array(digest.prefix(20))
			keyArray.append(contentsOf: digest.prefix(12))
			// let keyString = "\(sha1.prefix(20))\(sha1.prefix(12)))"
			let key = Data(keyArray) // Data(keyString.utf8)
			self.key = key
			completion(true)
		}
	}

	func decryptString(data: Data) -> String? {
		guard let plaindata = decrypt(data: data) else { return nil }
		let plaintext = String(data: plaindata, encoding: .utf16LittleEndian)
		return plaintext
	}

	func decryptData(data: Data) -> Data? {
		decrypt(data: data)
	}

	func encrypt(_ string: String) -> Data? {
		guard let utf16leData = string.data(using: .utf16LittleEndian) else {
			return nil
		}
		return encrypt(data: utf16leData)
	}

	func lock() {
		key = nil
	}

	deinit {
		lock()
	}

	private var key: Data?

	private func decrypt(data: Data) -> Data? {
		guard let key = key else { return nil }
		let paddingSize = data[0]
		let dataIn = data[4...]
		var dataOut = Data(count: dataIn.count)
		var numBytesDecrypted: size_t = 0
		var successBytes = 0
		dataOut.withUnsafeMutableBytes { dataOut in
			dataIn.withUnsafeBytes { dataIn in
				key.withUnsafeBytes { key in
					let success = CCCrypt(CCOperation(kCCDecrypt),
					                      CCAlgorithm(kCCAlgorithmAES),
					                      CCOptions(kCCOptionECBMode),
					                      key.baseAddress,
					                      key.count,
					                      nil,
					                      dataIn.baseAddress,
					                      dataIn.count,
					                      dataOut.baseAddress,
					                      dataIn.count,
					                      &numBytesDecrypted)

					guard Int32(success) == UInt32(kCCSuccess) else { return }

					successBytes = numBytesDecrypted
				}
			}
		}
		guard successBytes > 0 else { return nil }

		dataOut.count = successBytes - Int(paddingSize)
		return dataOut
	}

	private func encrypt(data: Data) -> Data? {
		guard let key = key else { return nil }
		var dataIn = data
		var paddingSize: UInt8 = 0
		while dataIn.count % 16 > 0 {
			dataIn.append(0)
			paddingSize += 1
		}
		var dataOut = Data(count: dataIn.count)
		var numBytesDecrypted: size_t = 0
		var successBytes = 0
		dataOut.withUnsafeMutableBytes { dataOut in
			dataIn.withUnsafeBytes { dataIn in
				key.withUnsafeBytes { key in
					let success = CCCrypt(CCOperation(kCCEncrypt),
					                      CCAlgorithm(kCCAlgorithmAES),
					                      CCOptions(kCCOptionECBMode),
					                      key.baseAddress,
					                      key.count,
					                      nil,
					                      dataIn.baseAddress,
					                      dataIn.count,
					                      dataOut.baseAddress,
					                      dataIn.count,
					                      &numBytesDecrypted)

					guard Int32(success) == UInt32(kCCSuccess) else { return }

					successBytes = numBytesDecrypted
				}
			}
		}

		guard successBytes > 0 else { return nil }

		var response = Data(count: 0)
		response.append(contentsOf: [paddingSize, 0, 0, 0])
		response.append(dataOut)
		return response
	}
}
