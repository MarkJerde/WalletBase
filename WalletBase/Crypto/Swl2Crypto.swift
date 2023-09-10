//
//  Swl2Crypto.swift
//  WalletBase
//
//  Created by Mark Jerde on 8/23/23.
//

import CommonCrypto
import Foundation

// Thanks, Stack Overflow! https://stackoverflow.com/a/25762128
extension String {
	func sha256() -> String {
		Data(utf8).sha256().string02hhx
	}
}

extension Data {
	func sha256() -> [UInt8] {
		var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
		withUnsafeBytes {
			_ = CC_SHA256($0.baseAddress, CC_LONG(count), &digest)
		}
		return digest
	}
}

extension [UInt8] {
	var string02hhx: String {
		let hexBytes = map { String(format: "%02hhx", $0) }
		return hexBytes.joined()
	}
}

class Swl2Crypto: CryptoProvider {
	func unlock(password: String, completion: @escaping (Bool) -> Void) {
		let password = "\(password)\0"

		// Adapted from https://stackoverflow.com/a/25762128
		guard let utf16leData = password.data(using: .utf16LittleEndian) else {
			completion(false)
			return
		}
		let digest = utf16leData.sha256()

		let key = Data(digest)
		self.key = key
		completion(true)
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
		guard !data.isEmpty,
		      let key = key else { return nil }
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
					                      CCOptions(kCCOptionPKCS7Padding),
					                      key.baseAddress,
					                      key.count,
					                      nil,
					                      dataIn.baseAddress,
					                      dataIn.count,
					                      dataOut.baseAddress,
					                      dataOut.count,
					                      &numBytesDecrypted)

					guard Int32(success) == UInt32(kCCSuccess) else { return }

					successBytes = numBytesDecrypted
				}
			}
		}
		guard successBytes > paddingSize else { return nil }

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
		// "A general rule for the size of the output buffer which must be provided by the caller is that for block ciphers, the output length is never larger than the input length plus the block size." (https://opensource.apple.com/source/CommonCrypto/CommonCrypto-60061/include/CommonCryptor.h#:~:text=A%20general%20rule%20for%20the,same%20as%20the%20input%20length.)
		var dataOut = Data(count: dataIn.count + kCCBlockSizeAES128)
		var numBytesDecrypted: size_t = 0
		var successBytes = 0
		dataOut.withUnsafeMutableBytes { dataOut in
			dataIn.withUnsafeBytes { dataIn in
				key.withUnsafeBytes { key in
					let success = CCCrypt(CCOperation(kCCEncrypt),
					                      CCAlgorithm(kCCAlgorithmAES),
					                      CCOptions(kCCOptionPKCS7Padding),
					                      key.baseAddress,
					                      key.count,
					                      nil,
					                      dataIn.baseAddress,
					                      dataIn.count,
					                      dataOut.baseAddress,
					                      dataOut.count,
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
