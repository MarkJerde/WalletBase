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
	init(keyDerivation: KeyDerivation) {
		self.keyDerivation = keyDerivation
	}

	enum KeyDerivation {
		case sha256
		case pbkdf2(iterations: Int32, salt: Data)
	}

	let keyDerivation: KeyDerivation

	func unlock(password: String) -> Bool {
		let password = "\(password)\0"

		// Adapted from https://stackoverflow.com/a/25762128
		guard let utf16leData = password.data(using: .utf16LittleEndian) else {
			return false
		}

		let key: Data?
		switch keyDerivation {
		case .sha256:
			let digest = utf16leData.sha256()
			key = Data(digest)
		case .pbkdf2(let iterations, let salt):
			// 512 even though we currently only need 256 based on somewhat old advice that hasn't been vetted relating to GPU processing being better suited for 32 bit values, making the 64-bit values for 512 less efficient. https://security.stackexchange.com/questions/17994/with-pbkdf2-what-is-an-optimal-hash-size-in-bytes-what-about-the-size-of-the-s
			key = PBKDF2.sha512.pbkdf2(password: utf16leData,
			                           salt: salt,
			                           rounds: UInt32(iterations))
		}

		guard let key else { return false }

		self.key = key
		return true
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

	private func decrypt(data dataIn: Data) -> Data? {
		guard !dataIn.isEmpty,
		      let key = key else { return nil }
		var dataOut = Data(count: dataIn.count)
		var numBytesDecrypted: size_t = 0
		var successBytes = 0
		dataOut.withUnsafeMutableBytes { dataOut in
			dataIn.withUnsafeBytes { dataIn in
				key.withUnsafeBytes { key in
					guard let dataInBaseAddress = dataIn.baseAddress else { return }
					let success = CCCrypt(CCOperation(kCCDecrypt),
					                      CCAlgorithm(kCCAlgorithmAES),
					                      CCOptions(kCCOptionPKCS7Padding),
					                      key.baseAddress,
					                      key.count,
					                      dataInBaseAddress, // The iv
					                      dataInBaseAddress + kCCBlockSizeAES128, // Advanced past the iv
					                      dataIn.count - kCCBlockSizeAES128, // Byte count without the iv
					                      dataOut.baseAddress,
					                      dataOut.count,
					                      &numBytesDecrypted)

					guard Int32(success) == UInt32(kCCSuccess) else { return }

					successBytes = numBytesDecrypted
				}
			}
		}
		guard successBytes > 0 else { return nil }

		return dataOut[..<successBytes]
	}

	func encrypt(data dataIn: Data) -> Data? {
		// Ensure we have a key and can generate an iv.
		guard let key = key,
		      let ivArray: [UInt8] = .cryptographicRandomBytes(count: kCCBlockSizeAES128) else { return nil }
		let iv = Data(ivArray)
		// "A general rule for the size of the output buffer which must be provided by the caller is that for block ciphers, the output length is never larger than the input length plus the block size." (https://opensource.apple.com/source/CommonCrypto/CommonCrypto-60061/include/CommonCryptor.h#:~:text=A%20general%20rule%20for%20the,same%20as%20the%20input%20length.)
		var dataOut = Data(count: dataIn.count + kCCBlockSizeAES128)
		var numBytesEncrypted: size_t = 0
		var successBytes = 0
		dataOut.withUnsafeMutableBytes { dataOut in
			dataIn.withUnsafeBytes { dataIn in
				iv.withUnsafeBytes { iv in
					key.withUnsafeBytes { key in
						let success = CCCrypt(CCOperation(kCCEncrypt),
						                      CCAlgorithm(kCCAlgorithmAES),
						                      CCOptions(kCCOptionPKCS7Padding),
						                      key.baseAddress,
						                      key.count,
						                      iv.baseAddress,
						                      dataIn.baseAddress,
						                      dataIn.count,
						                      dataOut.baseAddress,
						                      dataOut.count,
						                      &numBytesEncrypted)

						guard Int32(success) == UInt32(kCCSuccess) else { return }

						successBytes = numBytesEncrypted
					}
				}
			}
		}

		guard successBytes > 0 else { return nil }

		var response = Data(count: 0)
		response.append(iv) // Prefix on the iv.
		response.append(dataOut[..<successBytes]) // Then the cipher data.
		return response
	}
}
