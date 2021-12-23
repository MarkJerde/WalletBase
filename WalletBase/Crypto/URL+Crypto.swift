//
//  URL+Crypto.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/20/21.
//

import CommonCrypto
import Foundation

extension URL {
	var contentSHA256: Data? {
		// Thanks, Stack Overflow! https://stackoverflow.com/a/49878022
		do {
			let bufferSize = 1024 * 1024
			// Open file for reading:
			let file = try FileHandle(forReadingFrom: self)
			defer {
				file.closeFile()
			}

			// Create and initialize SHA256 context:
			var context = CC_SHA256_CTX()
			CC_SHA256_Init(&context)

			var success = Int32(kCCSuccess)

			// Read up to `bufferSize` bytes, until EOF is reached, and update SHA256 context:
			while autoreleasepool(invoking: {
				// Read up to `bufferSize` bytes
				let data = file.readData(ofLength: bufferSize)
				if data.count > 0 {
					let chunkSuccess = data.withUnsafeBytes { bytesFromBuffer -> Int32 in
						guard let rawBytes = bytesFromBuffer.bindMemory(to: UInt8.self).baseAddress else {
							return Int32(kCCMemoryFailure)
						}

						return CC_SHA256_Update(&context, rawBytes, numericCast(data.count))
					}

					if chunkSuccess != 1 /* CC_COMPAT_DIGEST_RETURN */, success == kCCSuccess {
						success = Int32(kCCUnspecifiedError)
					}

					// Continue
					return true
				} else {
					// End of file
					return false
				}
			}) {}

			if success != kCCSuccess {
				return nil
			}

			// Compute the SHA256 digest:
			var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
			let finalSuccess = digest.withUnsafeMutableBytes { bytesFromDigest -> Int32 in
				guard let rawBytes = bytesFromDigest.bindMemory(to: UInt8.self).baseAddress else {
					return Int32(kCCMemoryFailure)
				}

				return CC_SHA256_Final(rawBytes, &context)
			}

			if finalSuccess != 1 /* CC_COMPAT_DIGEST_RETURN */ {
				return nil
			}

			return digest
		} catch {
			print(error)
			return nil
		}
	}
}
