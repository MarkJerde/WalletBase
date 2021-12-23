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

	func makePasswordInputFirstResponder(attempt: Int = 1) {
		// SwiftUI doesn't yet, as of macOS 11, have a way to make our SecureField a first responder. So use an ugly hack that is pretty well protected to avoid any ill effects because having the password field not auto-focus is pretty bad.

		// An interesting thing, is that when .onAppear{} was executed, the prior screen content was still what we would find in mainWindow. Testing shows that an async without delay is enough to get what we want, but try for up to 400 ms to find the view we want.
		DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds((attempt == 1) ? 0 : 100)) {
			guard let view = NSApplication.shared.mainWindow?.contentViewController?.view.subviews[1].subviews[0].subviews[0],
			      view is NSSecureTextField
			else {
				if attempt < 5 {
					self.makePasswordInputFirstResponder(attempt: attempt + 1)
				}
				return
			}

			view.becomeFirstResponder()
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
