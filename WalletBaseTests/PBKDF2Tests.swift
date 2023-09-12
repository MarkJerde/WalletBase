//
//  PBKDF2Tests.swift
//  WalletBaseTests
//
//  Created by Mark Jerde on 9/11/23.
//

import XCTest

final class PBKDF2Tests: XCTestCase {
	let iterations = 147058
	let salt = Data([140, 153, 106, 161, 78, 130, 71, 6, 9, 248, 232, 248, 9, 188, 6, 3, 150, 100, 42, 234, 158, 39, 6, 82, 54, 42, 55, 206, 135, 6, 41, 75, 127, 217, 247, 188, 220, 108, 21, 42, 184, 85, 22, 182, 205, 86, 138, 167, 131, 253, 231, 147, 198, 106, 246, 1, 189, 157, 80, 56, 254, 92, 103, 249, 118, 211, 15, 200, 195, 147, 94, 227, 135, 107, 240, 138, 21, 212, 14, 190, 196, 213, 234, 188, 178, 247, 94, 117, 146, 243, 58, 2, 201, 156, 8, 85, 14, 223, 228, 205, 184, 3, 104, 128, 229, 16, 108, 79, 252, 230, 26, 28, 230, 253, 172, 195, 188, 24, 104, 233, 158, 16, 41, 44, 78, 91, 214, 235])
	let password = "correcthorsebatterystaple"
	lazy var utf16leData: Data = {
		let password = "\(password)\0"

		// Adapted from https://stackoverflow.com/a/25762128
		guard let utf16leData = password.data(using: .utf16LittleEndian) else {
			XCTFail("Failed to convert password")
			return Data()
		}

		return utf16leData
	}()

	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func testDerivation() throws {
		// Given

		// When

		let output = PBKDF2.sha512.pbkdf2(password: utf16leData, salt: salt, rounds: UInt32(iterations))

		// Then
		XCTAssertNotNil(output)
		XCTAssertEqual([228, 251, 221, 198, 161, 130, 170, 84, 130, 202, 90, 80, 5, 169, 61, 68, 133, 40, 238, 184, 146, 100, 29, 243, 25, 151, 91, 255, 213, 239, 226, 18], [UInt8](output ?? Data()))
	}

	func testDerivation256() throws {
		// Given

		// When

		let output = PBKDF2.sha256.pbkdf2(password: utf16leData, salt: salt, rounds: UInt32(iterations))

		// Then
		XCTAssertNotNil(output)
		XCTAssertEqual([79, 126, 175, 204, 4, 87, 94, 175, 89, 21, 74, 195, 76, 84, 247, 115, 13, 49, 181, 66, 46, 26, 49, 165, 199, 1, 151, 42, 57, 166, 184, 204], [UInt8](output ?? Data()))
	}

	func testDerivationIterations() throws {
		// Given

		// When

		let output = PBKDF2.sha512.pbkdf2(password: utf16leData, salt: salt, rounds: UInt32(iterations - 1))

		// Then
		XCTAssertNotNil(output)
		XCTAssertEqual([130, 249, 15, 85, 158, 216, 31, 96, 116, 248, 25, 125, 123, 245, 80, 20, 53, 102, 244, 38, 229, 151, 233, 39, 32, 137, 227, 150, 72, 56, 255, 61], [UInt8](output ?? Data()))
	}

	func testDerivationSalt() throws {
		// Given

		// When

		let output = PBKDF2.sha512.pbkdf2(password: utf16leData, salt: "peanuts".data(using: .utf8) ?? Data(), rounds: UInt32(iterations))

		// Then
		XCTAssertNotNil(output)
		XCTAssertEqual([252, 72, 45, 170, 27, 130, 25, 191, 60, 86, 224, 116, 226, 44, 130, 208, 101, 77, 157, 210, 198, 155, 125, 77, 34, 148, 107, 122, 188, 178, 196, 53], [UInt8](output ?? Data()))
	}

	func testPerformanceCalibration() throws {
		// This is an example of a performance test case.
		let iterations = PBKDF2.sha512.calibrate(forPasswordBytes: utf16leData.count, saltBytes: salt.count, milliseconds: 25)
		measure {
			// Put the code you want to measure the time of here.
			_ = PBKDF2.sha512.pbkdf2(password: utf16leData, salt: salt, rounds: UInt32(iterations))
		}
	}
}
