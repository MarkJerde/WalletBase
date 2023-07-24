//
//  Alert.swift
//  WalletBase
//
//  Created by Mark Jerde on 7/23/23.
//

import AppKit
import Foundation

enum Alert {
	case useAtYourOwnRisk
	case pasteFailed(errorText: String)
	case delete(type: String, name: String)
	case savePendingChanges
	case saveCompressedAttachement
	case writeFailureIndeterminite
	case deleteError(itemType: String)
	case deleteErrorNotEmpty(itemType: String)
	case failedToSave

	func show(completion: ((String) -> Void)? = nil) {
		DispatchQueue.main.async {
			let content = self.content

			let alert = NSAlert()
			if let title = content.title {
				alert.messageText = title
			}
			if let body = content.body {
				alert.informativeText = body
			}
			for button in content.buttons {
				alert.addButton(withTitle: button)
			}
			if let style = content.style {
				switch style {
				case .warning:
					alert.alertStyle = .warning
				case .informational:
					alert.alertStyle = .informational
				case .critical:
					alert.alertStyle = .critical
				}
			}

			let response = alert.runModal()
			switch response {
			case .alertFirstButtonReturn:
				completion?(content.buttons[0])
			case .alertSecondButtonReturn:
				completion?(content.buttons[1])
			case .alertThirdButtonReturn:
				completion?(content.buttons[2])
			default:
				break
			}
		}
	}

	struct Content {
		internal init(title: String? = nil,
		              body: String? = nil,
		              buttons: [String] = ["OK"],
		              style: Style? = nil)
		{
			self.title = title
			self.body = body
			self.buttons = buttons
			self.style = style
		}

		let title: String?
		let body: String?
		let buttons: [String]
		let style: Style?

		enum Style {
			case warning
			case informational
			case critical
		}
	}

	private var content: Content {
		switch self {
		case .useAtYourOwnRisk:
			return .init(title: "Use at your own risk!",
			             body: "THE AUTHOR SUPPLIES THIS SOFTWARE \"AS IS\", AND MAKES NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND. This software was written without expertise in data security and may have vulnerabilities which enable other software to capture your decrypted information, defects which result in a loss of data, or other ill effects. Users are encouraged to read the source code, made publicly available.",
			             buttons: [
			             	"Accept",
			             	"Cancel",
			             ])

		case .pasteFailed(let errorText):
			return .init(title: "Paste Failed",
			             body: errorText,
			             style: .critical)

		case .delete(let type, let name):
			return .init(title: "Delete \(type)?",
			             body: "Are you sure you want to delete the \"\(name)\" \(type.lowercased())? This action cannot be undone.",
			             buttons: [
			             	"Cancel",
			             	"Yes",
			             ],
			             style: .critical)

		case .savePendingChanges:
			return .init(title: "Save Changes?",
			             body: "Would you like to save changes before leaving this card?",
			             buttons: [
			             	"Save",
			             	"Discard",
			             	"Cancel",
			             ],
			             style: .warning)

		case .saveCompressedAttachement:
			return .init(title: "Save compressed attachment?",
			             body: "Attachments are compressed, though it's not clear what compression was used. But at least it's decrypted. Do you still want to save?",
			             buttons: [
			             	"OK",
			             	"Cancel",
			             ],
			             style: .warning)

		case .writeFailureIndeterminite:
			return .init(title: "Save Failed",
			             body: "Something went wrong while trying to save. Enough so that the wallet may be corrupted. You should probably at least close the wallet, reopen it, and check to see if things look right.",
			             buttons: [
			             	"Close Wallet",
			             	"Take More Risks",
			             ],
			             style: .critical)

		case .deleteError(let itemType):
			return .init(title: "Delete",
			             body: "An error occurred while trying to delete the \(itemType).",
			             style: .critical)

		case .deleteErrorNotEmpty(let itemType):
			return .init(title: "Delete",
			             body: "This \(itemType) cannot be deleted because it is not empty.",
			             style: .informational)

		case .failedToSave:
			return .init(title: "Save Failed",
			             body: "Something went wrong while trying to save. Please try again.",
			             style: .warning)
		}
	}
}
