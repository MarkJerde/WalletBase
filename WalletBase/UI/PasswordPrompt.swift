//
//  PasswordPrompt.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/14/21.
//

import SwiftUI

struct PasswordPrompt: View {
	@State private var password: String = ""

	var completion: (String?) -> Void

	var body: some View {
		VStack {
			Text("Please enter your password:")
				.padding()
			SecureField(
				"Password",
				text: $password
			) {
				completion(password)
			}
			.onAppear {
				makePasswordInputFirstResponder()
			}
			HStack {
				Spacer()
				Button("Cancel") {
					completion(nil)
				}
			}
		}.padding(.all, 20)
	}

	func makePasswordInputFirstResponder() {
		makeViewFirstResponder {
			(NSApplication.shared.mainWindow?.contentViewController?.view ?? NSApplication.shared.windows.first?.contentView)?.subviews[1].subviews[0].subviews[0] as? NSSecureTextField
		}
	}
}

struct PasswordPrompt_Previews: PreviewProvider {
	static var previews: some View {
		PasswordPrompt { _ in
			// No-op
		}
	}
}
