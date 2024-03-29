//
//  CardValue.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/6/21.
//

import Combine
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
	@State private var isShowingPopover: Bool = false {
		didSet {
			guard isShowingPopover != oldValue else { return }
			// Clear the newValue when toggling the popover. Without this the value previously entered is displayed again when editing a subsequent time.
			guard isShowingPopover
			else {
				// Delay one second because Catalina has shown that assigning the value synchronously when dismissing the popover will cause the value assigned to become the new value for the field. Possibly a nuance of when it calls the onCommit.
				DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
					newValue = ""
				}
				return
			}
			newValue = ""
		}
	}

	func makePopoverInputFirstResponder() {
		makeViewFirstResponder {
			guard let view = (NSApplication.shared.windows.last?.contentViewController?.view ?? NSApplication.shared.windows.last?.contentView)?.subviews.first?.subviews.first?.subviews.first,
			      "\(view)".contains("TextField") else { return nil }
			return view
		}
	}

	private func saveEdit() {
		onSet(newValue)
		value = isEncrypted ? "********" : newValue
		isShowingPopover = false
		// FIXME: This shows up on 10.15 after user enters a new username.
		// newValue = "alphabet"
	}

	struct DefaultButtonStyle: ButtonStyle {
		func makeBody(configuration: Self.Configuration) -> some View {
			// This color is ever so slightly off, but it's pretty good.
			// FIXME: Can we read this color from system preferences?
			let blue = Color(red: 46.0 / 255, green: 125.0 / 255, blue: 246.0 / 255)
			configuration.label
				.font(.body) // Without this the text would be slightly low and the button a pixel to wide.
				.padding(.horizontal, 8)
				.padding(.vertical, 2)
				.foregroundColor(configuration.isPressed ? blue : Color.white)
				.background(configuration.isPressed ? Color.white : blue)
				.cornerRadius(5.0)
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
						TextField(item.name, text: $newValue, onCommit: {
							saveEdit()
						})
						.frame(minWidth: 300)
						HStack {
							Spacer()
							Button("Cancel") {
								isShowingPopover = false
							}
							Button("Save") {
								saveEdit()
							}
							.buttonStyle(DefaultButtonStyle())
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
		.background(Color.tappableClear)
		.onTapGesture {
			if isEditing {
				isShowingPopover = !isShowingPopover
				guard isShowingPopover else { return }
				makePopoverInputFirstResponder()
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
	}

	private struct CopyButtonStyle: ButtonStyle {
		func makeBody(configuration: Self.Configuration) -> some View {
			configuration.label
				.padding()
				.background(configuration.isPressed ? Color.gray : Color(NSColor.textBackgroundColor))
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
