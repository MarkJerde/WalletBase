//
//  Swl2CryptoTests.swift
//  WalletBaseTests
//
//  Created by Mark Jerde on 9/11/23.
//

import XCTest

final class Swl2CryptoTests: XCTestCase {
	let crypto = Swl2Crypto(keyDerivation: .pbkdf2(iterations: 147058,
	                                               salt: Data([140, 153, 106, 161, 78, 130, 71, 6, 9, 248, 232, 248, 9, 188, 6, 3, 150, 100, 42, 234, 158, 39, 6, 82, 54, 42, 55, 206, 135, 6, 41, 75, 127, 217, 247, 188, 220, 108, 21, 42, 184, 85, 22, 182, 205, 86, 138, 167, 131, 253, 231, 147, 198, 106, 246, 1, 189, 157, 80, 56, 254, 92, 103, 249, 118, 211, 15, 200, 195, 147, 94, 227, 135, 107, 240, 138, 21, 212, 14, 190, 196, 213, 234, 188, 178, 247, 94, 117, 146, 243, 58, 2, 201, 156, 8, 85, 14, 223, 228, 205, 184, 3, 104, 128, 229, 16, 108, 79, 252, 230, 26, 28, 230, 253, 172, 195, 188, 24, 104, 233, 158, 16, 41, 44, 78, 91, 214, 235])))
	let cryptoSHA = Swl2Crypto(keyDerivation: .sha256)

	override func setUpWithError() throws {
		unlock()
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	private func unlock() {
		_ = crypto.unlock(password: "correcthorsebatterystaple")
		_ = cryptoSHA.unlock(password: "correcthorsebatterystaple")
	}

	//

	func testDecrypt() throws {
		// Given
		let input = "x'0E0000000F133D86B12EEEFF1FCBA544D6435F5B5BED8F8BD5F2F07AD68D8B65FAE40CCE378DE6A961F1791FC872D7BD02EE973020D1C65FD5AB018E4E0C831B27EF1CBA4562BC3A57C406006FD32A294A6038544C81A3D14F9F6EA672503B992443F5ED'"

		// When

		let output = crypto.decryptString(data: SQLiteDataItem(blobValue: input).asData)

		// Then
		XCTAssertEqual("Four score and seven years ago...", output)
	}

	func testWrongPassword() throws {
		// Given
		let input = "x'0E0000000F133D86B12EEEFF1FCBA544D6435F5B5BED8F8BD5F2F07AD68D8B65FAE40CCE378DE6A961F1791FC872D7BD02EE973020D1C65FD5AB018E4E0C831B27EF1CBA4562BC3A57C406006FD32A294A6038544C81A3D14F9F6EA672503B992443F5ED'"
			_ = crypto.unlock(password: "correcthorwebatterystaple")

		// When

		let output = crypto.decryptString(data: SQLiteDataItem(blobValue: input).asData)

		// Then
		XCTAssertNotEqual("Four score and seven years ago...", output)
	}

	func testTruncatedPassword() throws {
		// Given
		let input = "x'0E0000000F133D86B12EEEFF1FCBA544D6435F5B5BED8F8BD5F2F07AD68D8B65FAE40CCE378DE6A961F1791FC872D7BD02EE973020D1C65FD5AB018E4E0C831B27EF1CBA4562BC3A57C406006FD32A294A6038544C81A3D14F9F6EA672503B992443F5ED'"
			_ = crypto.unlock(password: "correcthorsebatterystapl")

		// When

		let output = crypto.decryptString(data: SQLiteDataItem(blobValue: input).asData)

		// Then
		XCTAssertNotEqual("Four score and seven years ago...", output)
	}

	func testRoundTripCrypto() throws {
		// Given
		let input = "Four score and seven years ago..."

		// When
		let encrypted = crypto.encrypt(input)
		let output: String?
		if let encrypted = encrypted {
			switch crypto.keyDerivation {
			case .pbkdf2(_, let salt):
				NSLog("\([UInt8](salt))")
			default:
				break
			}
			NSLog("\(SQLiteDataItem(dataValue: encrypted).asBlob)")
			output = crypto.decryptString(data: encrypted)
		} else {
			output = nil
		}

		// Then
		XCTAssertNotNil(encrypted)
		XCTAssertEqual(input, output)
	}

	func testDecryptSHA() throws {
		// Given
		let input = "x'0E0000004FCDB9F616A03419E96C72360D676D75BFD8D555ADB7F8AE7ED1E0243AF3ABAEC3FB1130EAE9941AC447A6B7576281A7361DD156278AF990788D19AD1F1C00E84AE8D7D5FF47FD55F6C040ECC0AF272AE71BB8FCE466823B58D6F202C4EFB85D'"

		// When

		let output = cryptoSHA.decryptString(data: SQLiteDataItem(blobValue: input).asData)

		// Then
		XCTAssertEqual("Four score and seven years ago...", output)
	}

	func testRoundTripCryptoSHA() throws {
		// Given
		let input = "Four score and seven years ago..."

		// When
		let encrypted = cryptoSHA.encrypt(input)
		let output: String?
		if let encrypted = encrypted {
			NSLog("\(SQLiteDataItem(dataValue: encrypted).asBlob)")
			output = cryptoSHA.decryptString(data: encrypted)
		} else {
			output = nil
		}

		// Then
		XCTAssertNotNil(encrypted)
		XCTAssertEqual(input, output)
	}

	func testLock() throws {
		// Given
		let input = "Four score and seven years ago..."

		// When
		let encrypted = crypto.encrypt(input)
		crypto.lock()
		let encrypted2 = crypto.encrypt(input)
		let output: String?
		if let encrypted = encrypted {
			output = crypto.decryptString(data: encrypted)
		} else {
			output = nil
		}

		// Then
		XCTAssertNotNil(encrypted)
		XCTAssertNil(encrypted2)
		XCTAssertNil(output)
	}

	func testLockUnlock() throws {
		// Given
		let input = "Four score and seven years ago..."

		// When
		let encrypted = crypto.encrypt(input)
		crypto.lock()
		let encrypted2 = crypto.encrypt(input)
		unlock()
		let output: String?
		if let encrypted = encrypted {
			output = crypto.decryptString(data: encrypted)
		} else {
			output = nil
		}

		// Then
		XCTAssertNotNil(encrypted)
		XCTAssertNil(encrypted2)
		XCTAssertEqual(input, output)
	}
}
