//
//  CardValue.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/6/21.
//

import SwiftUI

struct CardValue<Item: CardViewValue>: View {
	internal init(item: Item,
	              isEditing: Bool,
	              onSet: @escaping (String) -> Void)
	{
		self.item = item
		_value = State(initialValue: item.hidePlaintext ? "********" : (item.decryptedValue ?? ""))
		_isEncrypted = State(initialValue: item.hidePlaintext)
		self.isEditing = isEditing
		self.onSet = onSet
	}

	private let item: Item
	@State private var value: String
	@State private var newValue: String = ""
	@State private var isEncrypted: Bool
	@State private var isActive: Bool = false
	private let isEditing: Bool
	private var onSet: (String) -> Void
	@State private var isShowingPopover: Bool = false

	func makePopoverInputFirstResponder(attempt: Int = 1) {
		let subviews = String(describing: NSApplication.shared.mainWindow?.contentViewController?.view.subviews.last?.subviews.last?.subviews)
		print(subviews)
		// SwiftUI doesn't yet, as of macOS 11, have a way to make our SecureField a first responder. So use an ugly hack that is pretty well protected to avoid any ill effects because having the password field not auto-focus is pretty bad.

		// An interesting thing, is that when .onAppear{} was executed, the prior screen content was still what we would find in mainWindow. Testing shows that an async without delay is enough to get what we want, but try for up to 400 ms to find the view we want.
		DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds((attempt == 1) ? 0 : 100)) {
			if let view = NSApplication.shared.mainWindow?.contentViewController?.view {
				self.printSubviews(of: view, prefix: "\(attempt): ")
			}
			guard let view = NSApplication.shared.mainWindow?.contentViewController?.view.subviews[1].subviews[0].subviews[0],
			      view is NSSecureTextField
			else {
				if attempt < 5 {
					self.makePopoverInputFirstResponder(attempt: attempt + 1)
				}
				return
			}

			view.becomeFirstResponder()
		}
	}

	private func printSubviews(of view: NSView, prefix: String = "") {
		print("\(prefix) \(view)")
		for subview in view.subviews {
			printSubviews(of: subview, prefix: "\(prefix)  ")
		}
	}

	var body: some View {
		HStack {
			Text(item.name)
				.padding()
			Spacer()
			Text(value)
				.padding()
				.popover(isPresented: $isShowingPopover, arrowEdge: .bottom) {
					VStack {
						TextField(item.name, text: $newValue)
							.frame(minWidth: 300)
						HStack {
							Spacer()
							Button("Cancel") {
								isShowingPopover = false
							}
							Button("Save") {
								onSet(newValue)
								value = newValue
								isShowingPopover = false
							}
						}
					}
					.padding()
				}
			Button {
				if let value = item.decryptedValue {
					let pasteboard = NSPasteboard.general
					pasteboard.declareTypes([.string], owner: nil)
					pasteboard.setString(value, forType: .string)
					// FIXME: clear pasteboard after N seconds
				}
			} label: {
				Text("Copy")
			}
			.buttonStyle(CopyButtonStyle())
		}
		.background(Color.white.opacity(0.02)) // Minimum non-hidden opacity because hidden and clear items are not tappable in SwiftUI, or at least not as tappable.
		.onTapGesture {
			if isEditing {
				isShowingPopover = !isShowingPopover
			} else if item.hidePlaintext {
				if isEncrypted {
					value = item.decryptedValue ?? ""
				} else {
					value = "********"
				}
				isEncrypted = !isEncrypted
			} else if item.isURL,
			          let url = URL(string: value)
			{
				isActive = true
				NSWorkspace.shared.open(url, configuration: .init()) { _, _ in
					isActive = false
				}
			}
		}
		.overlay(
			RoundedRectangle(cornerRadius: 4)
				.stroke(isActive ? Color.blue : Color.gray, lineWidth: 2)
		)
		.onChange(of: isEditing) { isEditing in
			guard !isEditing else { return }
			// Reset the value, since if it weren't a cancel the card would have been reloaded.
			value = item.hidePlaintext ? "********" : (item.decryptedValue ?? "")
		}
		.onChange(of: isShowingPopover, perform: { isShowingPopover in
			guard isShowingPopover else { return }
			makePopoverInputFirstResponder()
		})
	}

	private struct CopyButtonStyle: ButtonStyle {
		func makeBody(configuration: Self.Configuration) -> some View {
			configuration.label
				.padding()
				.background(configuration.isPressed ? Color.gray : Color.white)
		}
	}
}

struct CardValue_Previews: PreviewProvider {
	static var previews: some View {
		VStack(spacing: 8) {
			CardValue(item: CardView_Previews_Value(name: "One", hidePlaintext: false, isURL: false, decryptedValue: "Uno"), isEditing: false, onSet: { _ in })
			CardValue(item: CardView_Previews_Value(name: "Two", hidePlaintext: true, isURL: false, decryptedValue: "Dos"), isEditing: false, onSet: { _ in })
			CardValue(item: CardView_Previews_Value(name: "Three", hidePlaintext: false, isURL: false, decryptedValue: "Tres"), isEditing: true, onSet: { _ in })
		}
		.padding()
	}
}
