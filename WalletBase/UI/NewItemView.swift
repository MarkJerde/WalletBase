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
	              getAvailableTemplates: @escaping (ItemType) -> [Template],
	              create: @escaping (NewItemView.ItemType, String, SwlDatabase.SwlID) -> Void,
	              cancel: @escaping () -> Void)
	{
		self.types = types
		self.getAvailableTemplates = getAvailableTemplates
		self.create = create
		self.cancel = cancel
	}

	private let types: [ItemType]
	private let getAvailableTemplates: (ItemType) -> [Template]
	private let create: (NewItemView.ItemType, String, SwlDatabase.SwlID) -> Void
	private let cancel: () -> Void

	enum ItemType: String, Identifiable {
		case folder
		case card

		var id: String { rawValue }
	}

	struct Template: Hashable {
		let id: SwlDatabase.SwlID
		let name: String?
	}

	@State private var currentType: ItemType?
	@State private var name: String = ""
	@State private var availableTemplates: [Template] = []
	// This must be non-optional for the Picker to work. Otherwise it will show options but never reflect the selected value.
	@State private var template = Template(id: .zero, name: "")
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
					availableTemplates = getAvailableTemplates(currentType ?? .folder)
					if let first = availableTemplates.first {
						template = first
					}
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
			Picker(currentType == .folder ? "Default Template:" : "Template:", selection: $template) {
				ForEach(availableTemplates, id: \.id) { template in
					if let name = template.name {
						Text(name)
							.tag(template)
					} else {
						// Per Stack Overflow, the Divider didn't work properly for this until macOS 12.4 or something. Assume 12.0 is where the difference happened until hearing otherwise. https://stackoverflow.com/a/63037859
						if #available(OSX 12.0, *) {
							Divider()
						} else {
							VStack { Divider().padding(.leading) }
						}
					}
				}
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
					create(currentType, name, template.id)
				}
				.buttonStyle(RoundedRectangleButtonStyle(foregroundColor: .white, backgroundColor: canCreate ? .blue : .gray))
				.buttonStyle(.automatic)
				.disabled(!canCreate)
				.compatibilityKeyboardShortcut(.defaultAction) { window in
					// NOTE: This may not be correct at all, but will need to be tested on an older OS to find out.
					guard let firstSubviews = (window.contentViewController?.view ?? window.contentView)?.subviews,
					      let secondSubviews = firstSubviews.prefix(2).last?.subviews,
					      let button = secondSubviews.first as? NSButton else { return nil }
					return button
				}
			}
		}
		.onAppear {
			// Set these in onAppear rather than in init because setting them in init is not effective.
			currentType = types.last
			updateCanCreate()
			availableTemplates = getAvailableTemplates(currentType ?? .folder)
			if let first = availableTemplates.first {
				template = first
			}
		}
	}
}

struct NewItemView_Previews: PreviewProvider {
	static var previews: some View {
		NewItemView(types: [.folder, .card]) { _ in
			[]
		} create: { type, name, templateID in
			NSLog("Creating \(type) with name \(name) template \(templateID)")
		} cancel: {
			NSLog("Cancel")
		}
	}
}
