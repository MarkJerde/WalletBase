//
//  CryptoProvider.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/14/21.
//

import Foundation

protocol CryptoProvider: AnyObject {
	func unlock(password: String, completion: @escaping (Bool) -> Void)
	func decryptString(data: Data) -> String?
	func decryptData(data: Data) -> Data?
	func encrypt(_ string: String) -> Data?
}
