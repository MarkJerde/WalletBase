//
//  CompatibilityVGrid.swift
//  WalletBase
//
//  Created by Mark Jerde on 1/8/23.
//

import SwiftUI

/// A container view that arranges its child views in a grid that grows vertically, creating items only as needed. A wrapper to provide LazyVGrid where available and a hack of a grid where LazyVGrid is not available.
struct CompatibilityVGrid<Data, ID, Content>: View where Data: RandomAccessCollection, ID: Hashable, Content: View {
	let data: Data
	let id: KeyPath<Data.Element, ID>
	@ViewBuilder let content: (Data.Element) -> Content

	var body: some View {
		if #available(macOS 11.0, *) {
			LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 20) {
				ForEach(data, id: id) { item in
					content(item)
				}
			}
		} else {
			// Note: This is rather gross.
			HStack(alignment: .top) {
				ForEach(Array(data.enumerated())
					.filter { offset, _ in
						offset < 5
					}
					.map { $0.offset }, id: \.self) { column in
						VStack(alignment: .center, spacing: 20) {
							ForEach(Array(data.enumerated())
								.filter { offset, _ in
									offset % 5 == column
								}
								.map { $0.element }, id: id) { item in
									content(item)
								}
						}
						.frame(maxWidth: .infinity)
					}
			}
			.frame(maxWidth: .infinity)
			.padding()
		}
	}
}

struct CompatibilityVGrid_Previews: PreviewProvider {
	static let words = [
		"alpha",
		"bravo",
		"charlie",
	]
	static var previews: some View {
		CompatibilityVGrid(data: words, id: \.self) { word in
			Text(word)
		}
	}
}
