//
//  SwlTemplateField+SQLiteQueryDescribing.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.TemplateField: SQLiteQueryDescribing {
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
}
