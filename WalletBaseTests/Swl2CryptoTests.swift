//
//  Swl2CryptoTests.swift
//  WalletBaseTests
//
//  Created by Mark Jerde on 9/11/23.
//

import XCTest

final class Swl2CryptoTests: XCTestCase {
	let crypto = Swl2Crypto(keyDerivation: .pbkdf2(iterations: 147058,
	                                               salt: Data([202, 228, 62, 45, 252, 192, 75, 205, 253, 126, 94, 194, 217, 190, 51, 33])))
	let cryptoSHA = Swl2Crypto(keyDerivation: .sha256)
	let password = "correcthorsebatterystaple"
	let plaintext = "Four score and seven years ago..."
	let ciphertextWithPBKDF2 = "x'E69F80DFF54FA3DDCCB91AE9355DA06BAB81A4BC8CC5AA504B4DF6E59F8F2E5FC8C27C5F82FBA661837EDAB3D84B522F28C54ED76D0B171A604A7027FC2275ED188C713BFE14B2E334B844F698332327AE493CD2DFCB19B91B5AD87DECABF8C4'"
	let ciphertextWithSHA256 = "x'B097687500489021C762CB840AC0A0547122BC5B35FA522B10BD4C038290280D916DC88C012519744ACC4BDC84466D2B2790CE8A8AD97743A5A4C54CE8FA6DAD9603C0E9C90DB8D2BAD014F96167608968B31E65D90E4FC167EF890E54DD82B3'"

	override func setUpWithError() throws {
		unlock()
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	private func unlock() {
		_ = crypto.unlock(password: password)
		_ = cryptoSHA.unlock(password: password)
	}

	//

	func testDecrypt() throws {
		// Given
		let input = ciphertextWithPBKDF2

		// When

		let output = crypto.decryptString(data: SQLiteDataItem(blobValue: input).asData)

		// Then
		XCTAssertEqual(plaintext, output)
	}

	func testWrongPassword() throws {
		// Given
		let input = ciphertextWithPBKDF2
		_ = crypto.unlock(password: "correcthorwebatterystaple")

		// When

		let output = crypto.decryptString(data: SQLiteDataItem(blobValue: input).asData)

		// Then
		XCTAssertNotEqual(plaintext, output)
	}

	func testTruncatedPassword() throws {
		// Given
		let input = ciphertextWithPBKDF2
		_ = crypto.unlock(password: "correcthorsebatterystapl")

		// When

		let output = crypto.decryptString(data: SQLiteDataItem(blobValue: input).asData)

		// Then
		XCTAssertNotEqual(plaintext, output)
	}

	func testRoundTripCrypto() throws {
		// Given
		let input = plaintext

		// When
		let encrypted = crypto.encrypt(input)
		let output: String?
		if let encrypted = encrypted {
			/* Logging to capture salt and cipher values to provide to other tests.
			 switch crypto.keyDerivation {
			 case .pbkdf2(_, let salt):
			 	NSLog("salt: \([UInt8](salt))")
			 default:
			 	break
			 }
			 NSLog("cipher: \(SQLiteDataItem(dataValue: encrypted).asBlob)")
			  */
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
		let input = ciphertextWithSHA256

		// When

		let output = cryptoSHA.decryptString(data: SQLiteDataItem(blobValue: input).asData)

		// Then
		XCTAssertEqual(plaintext, output)
	}

	func testRoundTripCryptoSHA() throws {
		// Given
		let input = plaintext

		// When
		let encrypted = cryptoSHA.encrypt(input)
		let output: String?
		if let encrypted = encrypted {
			/* Logging to capture salt and cipher values to provide to other tests.
			 NSLog("\(SQLiteDataItem(dataValue: encrypted).asBlob)")
			  */
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
		let input = plaintext

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
		let input = plaintext

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
