//
//  SwlCryptoTests.swift
//  WalletBaseTests
//
//  Created by Mark Jerde on 8/19/22.
//

import XCTest

class SwlCryptoTests: XCTestCase {
	let crypto = SwlCrypto()

	override func setUpWithError() throws {
		unlock()
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	private func unlock() {
		_ = crypto.unlock(password: "abc123")
	}

	//

	func testDecrypt() throws {
		// Given
		let input = "x'0E00000032A96EC163C8EFAFF7A43F122C850572D4F5ADF5A95894A1348929E8F9E18EEF8124300C68E99B58889034410476F7CB36463BD101843A890EF2902B5F5EF924E30DD13F3D6E57E47F2305B3B7986DD9'"

		// When

		let output = crypto.decryptString(data: SQLiteDataItem(blobValue: input).asData)

		// Then
		XCTAssertEqual("Four score and seven years ago...", output)
	}

	func testRoundTripCrypto() throws {
		// Given
		let input = "Four score and seven years ago..."

		// When
		let encrypted = crypto.encrypt(input)
		let output: String?
		if let encrypted = encrypted {
			output = crypto.decryptString(data: encrypted)
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
