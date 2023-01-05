//
//  Image+OldOS.swift
//  WalletBase
//
//  Created by Mark Jerde on 1/3/23.
//

import SwiftUI

extension Image {
	@ViewBuilder
	/// A view that displays an image from a system name, or from a bundled asset if below macOS 11. Incorporates color and size as parameters because when using a bundled asset they cannot be specified in the same way as when using SF Symbols.
	/// - Parameters:
	///   - systemName: The name of the system symbol image. Use the SF Symbols app to look up the names of system symbol images.
	///   - color: The color of the foreground elements displayed by this view.
	///   - size: The system font to use.
	/// - Returns: The view.
	static func image(systemName: String, color: Color, size: CGFloat) -> some View {
		if #available(macOS 11.0, *) {
			Image(systemName: systemName)
				.font(.system(size: size))
				.foregroundColor(color)
		} else {
			if let image = NSImage(named: systemName) {
				let tintedImage = image.tint(color: color.nsColor) ?? image
				Image(nsImage: tintedImage)
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(height: size)
			} else {
				Color.clear
			}
		}
	}
}

private extension NSImage {
	func tint(color: NSColor) -> NSImage? {
		// Thanks, Stack Overflow! https://stackoverflow.com/a/50074538
		guard let image = copy() as? NSImage else {
			return nil
		}

		image.lockFocus()

		color.set()

		let imageRect = NSRect(origin: NSZeroPoint, size: image.size)
		imageRect.fill(using: .sourceAtop)

		image.unlockFocus()

		return image
	}
}

private extension Color {
	// Thanks, Stack Overflow! https://stackoverflow.com/a/58531033

	var nsColor: NSColor {
		if #available(macOS 11.0, *) {
			return NSColor(self)
		}

		let components = components
		return NSColor(red: components.r,
		               green: components.g,
		               blue: components.b,
		               alpha: components.a)
	}

	private var components: (r: CGFloat,
	                         g: CGFloat,
	                         b: CGFloat,
	                         a: CGFloat) {
		let scanner = Scanner(string: self.description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
		var hexNumber: UInt64 = 0
		var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0

		let result = scanner.scanHexInt64(&hexNumber)
		if result {
			r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
			g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
			b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
			a = CGFloat(hexNumber & 0x000000ff) / 255
		}
		return (r, g, b, a)
	}
}
