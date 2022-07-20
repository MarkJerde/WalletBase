//
//  WalletFile.swift
//  WalletBase
//
//  Created by Mark Jerde on 7/19/22.
//

import Foundation

struct WalletFile: ItemGridItem, Hashable {
	/// The URL of the file.
	var name: String {
		url.lastPathComponent
	}

	/// The URL of the file.
	let url: URL
	/// The type of the file.
	let itemType: ItemType

	/// The type of the file.
	var type: ItemGridItemType {
		switch itemType {
		case .folder:
			return .category
		case .file:
			return .file
		}
	}

	internal init(url: URL, type: ItemType) {
		self.url = url
		self.itemType = type
	}

	static func == (lhs: WalletFile, rhs: WalletFile) -> Bool {
		lhs.url == rhs.url
	}

	func hash(into hasher: inout Hasher) {
		type.hash(into: &hasher)
		url.hash(into: &hasher)
	}

	enum ItemType {
		case folder
		case file
	}
}
