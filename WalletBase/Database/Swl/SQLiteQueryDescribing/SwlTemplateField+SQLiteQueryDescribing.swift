//
//  SwlTemplateField+SQLiteQueryDescribing.swift
//  WalletBase
//
//  Created by Mark Jerde on 12/19/21.
//

import Foundation

extension SwlDatabase.SwlTemplateField: SQLiteQueryDescribing {
	static let columns = ["ID", "Name", "TemplateID", "FieldTypeID", "Priority", "AdvInfo"]
	static let table: SQLiteTable = SwlDatabase.Tables.templateFields
}
