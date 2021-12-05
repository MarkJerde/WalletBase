//
//  CardValuesComposite.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/3/21.
//

import Foundation

struct CardValuesComposite: CardViewItem {
	var name: String
	var values: [CardValue]

	struct CardValue: CardViewValue {
		var name: String
		var hidePlaintext: Bool
		var encryptedValue: [UInt8]
		var decryptor: ([UInt8]) -> String?

		var decryptedValue: String? {
			decryptor(encryptedValue)
		}

		static func == (lhs: CardValuesComposite.CardValue, rhs: CardValuesComposite.CardValue) -> Bool {
			lhs.name == rhs.name
				&& lhs.hidePlaintext == rhs.hidePlaintext
				&& lhs.encryptedValue == rhs.encryptedValue
		}

		func hash(into hasher: inout Hasher) {
			name.hash(into: &hasher)
			hidePlaintext.hash(into: &hasher)
			encryptedValue.hash(into: &hasher)
		}
	}
}
