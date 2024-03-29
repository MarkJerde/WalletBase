//
//  MenuView.swift
//  WalletBase
//
//  Created by Mark Jerde on 3/12/23.
//

import SwiftUI

struct MenuView: View {
	internal init(title: String? = nil,
	              message: String? = nil,
	              options: [Option],
	              handler: @escaping (String, [String: String]) -> Void)
	{
		self.title = title
		self.message = message
		self.options = options
		self.handler = handler
		_backgroundColor = .init(initialValue: .tappableClear)
		fieldValues = [String](repeating: "", count: options.count)
	}

	let title: String?
	let message: String?
	let options: [Option]
	let handler: (String, [String: String]) -> Void

	enum Option: Hashable {
		case button(text: String)
		case field(id: String)
	}

	@State private var backgroundColor: Color

	@State private var fieldValues: [String]

	var body: some View {
		VStack(spacing: 0) {
			Divider().opacity(0)
			if let title {
				Text(title)
					.font(.headline)
					.padding(.horizontal)
					.padding(8)
			}
			if let message {
				Text(message)
					.font(.subheadline)
					.padding(.horizontal)
					.padding(.top, title == nil ? 8 : 0)
					.padding(.bottom, 8)
			}
			if title != nil || message != nil {
				Divider()
			}
			ForEach(Array(options.enumerated()), id: \.element) { item in
				switch item.element {
				case .button(let text):
					Button {
						let fieldValuesDictionary: [String: String] = Dictionary(
							uniqueKeysWithValues:
							options
								.enumerated()
								.compactMap { item in
									let key: String
									switch item.element {
									case .field(let title):
										key = title
									default:
										return nil
									}

									let value = fieldValues[item.offset]

									return (key, value)
								}
						)
						handler(text, fieldValuesDictionary)
					} label: {
						Text(text)
					}
					.buttonStyle(OptionButtonStyle(backgroundColor: backgroundColor))
					.eraseToAnyView
				case .field(let title):
					TextField(title, text: $fieldValues[item.offset])
						.foregroundColor(Color.black)
						.eraseToAnyView
				}
				if item.offset < (options.count - 1) {
					Divider()
				}
			}
			Divider().opacity(0)
		}
		.background(
			RoundedRectangle(cornerRadius: 5)
				.stroke(.separator, lineWidth: 1)
				.background(
					RoundedRectangle(cornerRadius: 5)
						.fill(backgroundColor)
				)
		)
	}

	struct OptionButtonStyle: ButtonStyle {
		let backgroundColor: Color
		func makeBody(configuration: Self.Configuration) -> some View {
			configuration.label
				.font(.body)
				.padding(.horizontal)
				.padding(.vertical, 8)
				.frame(maxWidth: .infinity)
				.background(configuration.isPressed ? Color.black.opacity(0.2) : Color.clear)
				.background(Color.tappableClear)
		}
	}
}

extension MenuView {
	@inlinable public func backgroundColor(_ color: Color?) -> Self {
		var view = self
		view._backgroundColor = State(initialValue: color ?? .tappableClear)
		return view
	}
}

struct MenuView_Previews: PreviewProvider {
	static var previews: some View {
		MenuView(title: "Title", message: "Message here", options: [
			.button(text: "Abort"),
			.button(text: "Retry"),
			.button(text: "Fail"),
		]) { selection, _ in
			NSLog("Selected \(selection)")
		}
		.backgroundColor(.yellow)
		.foregroundColor(.black)
		.fixedSize()
		.padding()
		.frame(maxWidth: .infinity)
	}
}
