//
//  SwlTemplateField.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/4/21.
//

import Foundation

extension SwlDatabase {
	/// An swl database template field.
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
		/// The advanced info of this field.
		let advancedInfo: [UInt8]?

		enum FieldType: Int32 {
			/// Text
			case plaintext = 1
			/// UPPER CASE
			case idNumber = 2
			/// Proper Case
			case name = 3
			/// PIN/Password
			case password = 4
			/// Web Address/URL
			case url = 6
			/// Email
			case email = 7
			/// Phone Number
			case phone = 8
		}
	}
}
