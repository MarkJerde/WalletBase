//
//  SwlTemplateField.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/4/21.
//

import Foundation

extension SwlDatabase {
	/// An swl database card.
	struct TemplateField {
		/// The ID of this field.
		let id: SwlID
		/// The encrypted name of this field.
		let name: [UInt8]
		/// The template ID of this field.
		let templateId: SwlID
		/// The field type.
		let fieldTypeId: Int32
		/// The priority of this field.
		let priority: Int32
		/// The encrypted advanced info of this field.
		let advancedInfo: [UInt8]?
	}
}
