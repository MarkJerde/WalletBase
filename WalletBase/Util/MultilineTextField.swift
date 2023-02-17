//
//  MultilineTextField.swift
//  WalletBase
//
//  Created by Mark Jerde on 2/16/23.
//

import SwiftUI

struct MultilineTextField: View {
	init(_ placeholder: String, text: Binding<String>) {
		self.placeholder = placeholder
		_text = text
	}

	let placeholder: String
	@Binding var text: String

	var body: some View {
		if #available(macOS 13.0, *) {
			TextField(placeholder, text: $text, axis: .vertical)
		} else {
			// Fallback on earlier versions
			TextField(placeholder, text: $text)
		}
	}
}

struct MultilineTextField_Previews: PreviewProvider {
	static var previews: some View {
		MultilineTextField("", text: .constant("text"))
	}
}
