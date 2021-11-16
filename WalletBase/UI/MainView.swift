//
//  MainView.swift
//  WalletBase
//
//  Created by Mark Jerde on 11/10/21.
//

import SwiftUI

struct MainView: View {
	private enum MyState {
		case buttonToUnlock
		case unlocking(database: SwlDatabase)
		case passwordPrompt(database: SwlDatabase, completion: (String) -> Void)
		case browseContent(database: SwlDatabase)
	}

	@State private var state: MyState = .buttonToUnlock

	var body: some View {
		switch state {
		case .buttonToUnlock:
			Button("Unlock") {
				let database = SwlDatabase(file: "foo")
				state = .unlocking(database: database)
			}
			.padding(.all, 20)
		case .unlocking(let database):
			Text("Unlocking...")
				.onAppear {
					database.open { completion in
						state = .passwordPrompt(database: database, completion: completion)
					} completion: { success in
						guard success else {
							state = .buttonToUnlock
							return
						}

						state = .browseContent(database: database)
					}
				}
		case .passwordPrompt(_, let completion):
			PasswordPrompt { password in
				guard let password = password else {
					state = .buttonToUnlock
					return
				}
				completion(password)
			}
		case .browseContent(let database):
			VStack {
				Text("Decrypted:")
				Text(database.test() ?? "ERROR")
				Button("Lock") {
					state = .buttonToUnlock
				}
			}
			.padding(.all, 20)
		}
	}
}

struct InitialView_Previews: PreviewProvider {
	static var previews: some View {
		MainView()
	}
}
