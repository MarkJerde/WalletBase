//
//  SwlTemplateField+SQLiteQuerySelectable.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.TemplateField: SQLiteQuerySelectable {
	enum Column: String {
		case id
		case name
		case templateID
		case fieldTypeID
		case priority
		case advInfo
	}

	static let columns: [Column] = [.id, .name, .templateID, .fieldTypeID, .priority, .advInfo]
	static let table = SwlDatabase.Tables.templateFields
	func encode() -> [Column: SQLiteDataType] {
		[
			.id: id.encoded,
			.name: .blob(value: .init(arrayValue: name)),
			.templateID: templateId.encoded,
			.fieldTypeID: .integer(value: fieldTypeId),
			.priority: .integer(value: priority),
			.advInfo: .nullableBlob(value: nil),
		]
	}
}
