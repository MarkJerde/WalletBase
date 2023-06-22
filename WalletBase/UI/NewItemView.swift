//
//  NewItemView.swift
//  WalletBase
//
//  Created by Mark Jerde on 6/19/23.
//

import SwiftUI

extension Binding {
	func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
		// Thanks, Stack Overflow! https://stackoverflow.com/a/60130311
		Binding(
			get: { wrappedValue },
			set: { selection in
				wrappedValue = selection
				handler(selection)
			}
		)
	}
}

struct NewItemView: View {
	internal init(types: [NewItemView.ItemType],
	              availableTemplates: [SwlDatabase.Template],
	              create: @escaping (NewItemView.ItemType, String) -> Void,
	              cancel: @escaping () -> Void)
	{
		self.types = types
		self.availableTemplates = availableTemplates
		self.create = create
		self.cancel = cancel
	}

	let types: [ItemType]
	let create: (ItemType, String) -> Void
	let cancel: () -> Void

	enum ItemType: String, Identifiable {
		case folder
		case card

		var id: String { rawValue }
	}

	@State private var currentType: ItemType?
	@State private var name: String = ""
	@State private var templateName: String = ""
	private let availableTemplates: [SwlDatabase.Template]
	@State private var template: SwlDatabase.Template? = nil
	@State private var canCreate = false
	@State private var createButtonText: String = ""

	private func updateCanCreate() {
		createButtonText = "Create \(currentType?.rawValue.capitalized ?? "")"
		guard currentType != nil,
		      !name.isEmpty
		else {
			canCreate = false
			return
		}
		canCreate = true
	}

	/// Not a thrilling recreation of the default Button style, but it's okay enough and allows the foreground / background support that we need.
	struct RoundedRectangleButtonStyle: ButtonStyle {
		let foregroundColor: Color
		let backgroundColor: Color
		func makeBody(configuration: Configuration) -> some View {
			configuration.label
				.foregroundColor(foregroundColor)
				.padding(2.5)
				.padding(.horizontal, 5)
				.background(
					RoundedRectangle(cornerRadius: 5)
						.stroke(.separator, lineWidth: 1)
						.background(
							RoundedRectangle(cornerRadius: 5)
								.fill(backgroundColor.opacity(configuration.isPressed ? 0.9 : 1))
								.background(
									RoundedRectangle(cornerRadius: 5)
										.fill(.black)
								)
						)
						.clipShape(RoundedRectangle(cornerRadius: 5))
						.shadow(color: .gray, radius: 1)
				)
		}
	}

	var body: some View {
		VStack {
			if types.count > 1 {
				Picker(selection: $currentType.onChange { _ in
					updateCanCreate()
				},
				label: Text("")) {
					ForEach(types) { item in
						Text(item
							.rawValue
							.capitalized)
							.tag(item as ItemType?) // It must be cast as the nullable type it is certainly a non-nil of in order to show the initial selection.
					}
				}
				.labelsHidden()
				.pickerStyle(SegmentedPickerStyle())
			}
			HStack {
				Text("Name:")
				TextField("Name", text: $name.onChange { _ in
					updateCanCreate()
				})
			}
			HStack {
				Text(currentType == .folder ? "Default Template:" : "Template:")
				TextField("Name", text: $templateName, onCommit: {
					updateCanCreate()
				})
			}
			HStack {
				Spacer()
				Button("Cancel", action: cancel)
					.buttonStyle(RoundedRectangleButtonStyle(foregroundColor: .black, backgroundColor: .white))
				Button(createButtonText) {
					guard let currentType else {
						cancel()
						return
					}
					create(currentType, name)
				}
				.buttonStyle(RoundedRectangleButtonStyle(foregroundColor: .white, backgroundColor: canCreate ? .blue : .gray))
				.buttonStyle(.automatic)
				.disabled(!canCreate)
			}
		}
		.onAppear {
			// Set these in onAppear rather than in init because setting them in init is not effective.
			currentType = types.first
			updateCanCreate()
		}
	}
}

struct NewItemView_Previews: PreviewProvider {
	static var previews: some View {
		NewItemView(types: [.folder, .card], availableTemplates: []) { type, name in
			NSLog("Creating \(type) with name \(name)")
		} cancel: {
			NSLog("Cancel")
		}
	}
}
