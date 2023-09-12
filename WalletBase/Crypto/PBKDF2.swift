//
//  PBKDF2.swift
//  WalletBase
//
//  Created by Mark Jerde on 9/10/23.
//

import CommonCrypto
import Foundation

enum PBKDF2 {
	case sha1
	case sha256
	case sha512

	/// Derives a key from a password Data
	/// - Parameters:
	///   - password: The password
	///   - salt: The salt
	///   - rounds: The number of rounds to iterate
	/// - Returns: The key
	func pbkdf2(password: Data,
	            salt: Data,
	            rounds: UInt32) -> Data?
	{
		// Thanks, Stack Overflow! https://stackoverflow.com/a/25702855
		var success = Int32(kCCSuccess)
		var derivedKeyData = Data(repeating: 0, count: keySize)

		derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
			password.withUnsafeBytes { passwordBytes in
				salt.withUnsafeBytes { saltBytes in
					success = CCKeyDerivationPBKDF(
						algorithm,
						passwordBytes.baseAddress,
						passwordBytes.count,
						saltBytes.baseAddress,
						saltBytes.count,
						pseudoRandomAlgorithm,
						rounds,
						derivedKeyBytes.baseAddress,
						derivedKeyBytes.count)
				}
			}
		}

		guard success == UInt32(kCCSuccess) else {
			return nil
		}

		return derivedKeyData
	}

	/// Calculates the number of rounds which can be completed for the given parameters.
	/// - Parameters:
	///   - passwordBytes: The number of bytes in the password
	///   - saltBytes: The number of bytes in the salt
	///   - milliseconds: The maximum number of milliseconds to iterate for
	/// - Returns: The number of rounds
	func calibrate(forPasswordBytes passwordBytes: Int,
	               saltBytes: Int,
	               milliseconds: Int) -> UInt32
	{
		// Thanks, DevTut! https://devtut.github.io/swift/pbkdf2-key-derivation.html#password-based-key-derivation-calibration-swift-2-3
		CCCalibratePBKDF(
			algorithm,
			passwordBytes,
			saltBytes,
			pseudoRandomAlgorithm,
			keySize,
			UInt32(milliseconds))
	}

	private var algorithm: CCPBKDFAlgorithm {
		CCPBKDFAlgorithm(kCCPBKDF2)
	}

	private var pseudoRandomAlgorithm: CCPseudoRandomAlgorithm {
		switch self {
		case .sha1:
			return CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1)
		case .sha256:
			return CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256)
		case .sha512:
			return CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA512)
		}
	}

	private var keySize: Int {
		switch self {
		case .sha1:
			return kCCKeySizeAES128
		case .sha256:
			return kCCKeySizeAES256
		case .sha512:
			return kCCKeySizeAES256
		}
	}
}
