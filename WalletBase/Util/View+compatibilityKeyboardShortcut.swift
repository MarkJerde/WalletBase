//
//  View+compatibilityKeyboardShortcut.swift
//  WalletBase
//
//  Created by Mark Jerde on 2/16/23.
//

import SwiftUI

enum CompatibilityKeyboardShortcut {
	case defaultAction

	@available(macOS 11.0, *)
	var keyboardShortcut: KeyboardShortcut {
		switch self {
		case .defaultAction:
			return .defaultAction
		}
	}
}

extension View {
	func compatibilityKeyboardShortcut(_ shortcut: CompatibilityKeyboardShortcut,
	                                   _ getButtonInWindow: @escaping (NSWindow) -> NSButton?) -> some View
	{
		if #available(macOS 11.0, *) {
			return self
				.keyboardShortcut(shortcut.keyboardShortcut)
		} else {
			return self
				.onAppear {
					makeButtonDefault(getButtonInWindow)
				}
		}
	}
}
