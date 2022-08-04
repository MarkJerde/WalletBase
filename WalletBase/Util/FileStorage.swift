//
//  FileStorage.swift
//  WalletBase
//
//  Created by Mark Jerde on 7/19/22.
//

import Foundation

struct FileStorage {
	/// The location of storage.
	private static var directory: URL = {
		let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		guard let url = urls.first else {
			let homeDirectory = URL(fileURLWithPath: NSHomeDirectory())
			let walletsDirectory = homeDirectory.appendingPathComponent("Wallets")
			try? FileManager.default.createDirectory(at: walletsDirectory,
			                                         withIntermediateDirectories: true,
			                                         attributes: nil)
			return walletsDirectory
		}
		return url
	}()

	/// The items in storage, ordered from most recent to least recent.
	static var items: [URL] {
		guard var currentContents = try? FileManager.default.contentsOfDirectory(
			at: directory,
			includingPropertiesForKeys: [.addedToDirectoryDateKey],
			options: .skipsSubdirectoryDescendants)
		else {
			return []
		}

		currentContents.sort(by: {
			guard let date0 = try? $0.resourceValues(forKeys: [.addedToDirectoryDateKey]).addedToDirectoryDate,
			      let date1 = try? $1.resourceValues(forKeys: [.addedToDirectoryDateKey]).addedToDirectoryDate
			else {
				let filename0 = $0.lastPathComponent
				let filename1 = $1.lastPathComponent
				return filename0.compare(filename1, options: .numeric) == .orderedDescending
			}

			return date0 < date1
		})

		return currentContents
	}

	/// Import a file into the file storage.
	/// - Parameter url: The file to import
	/// - Returns: The location of the file after being imported.
	@discardableResult
	static func importFile(at url: URL) -> URL? {
		let filename = url.lastPathComponent
		var destination = directory.appendingPathComponent(filename)

		var n = 1
		while true {
			do {
				try FileManager.default.copyItem(at: url, to: destination)
				return destination
			} catch {
				guard (error as NSError).domain == NSCocoaErrorDomain,
				      (error as NSError).code == NSFileWriteFileExistsError
				else {
					return nil
				}

				n += 1
				guard let parts = filename.splitOnLastOccurence(of: ".") else {
					destination = directory.appendingPathComponent("\(filename) - \(n)")
					continue
				}
				destination = directory.appendingPathComponent("\(parts.0) - \(n).\(parts.1)")
			}
		}
	}

	/// Create a backup copy of a file.
	/// - Parameter url: The file to backup
	/// - Returns: The location of the backup copy.
	@discardableResult
	static func backupFile(at url: URL) -> URL? {
		let modificationDate = fileModificationDate(url: url) ?? Date()

		let pathExtension = "\(backupDateFormatter.string(from: modificationDate)).bak"

		let destination = url.appendingPathExtension(pathExtension)

		do {
			try FileManager.default.copyItem(at: url, to: destination)
			return destination
		} catch {
			if FileManager.default.fileExists(atPath: destination.path) {
				// Already backed up today.
				return destination
			}
			// Error.
			return nil
		}
	}

	private static let backupDateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyyMMdd"
		return formatter
	}()

	private static func fileModificationDate(url: URL) -> Date? {
		do {
			let attr = try FileManager.default.attributesOfItem(atPath: url.path)
			return attr[FileAttributeKey.modificationDate] as? Date
		} catch {
			return nil
		}
	}

	/// Determine if a file URL is in storage.
	/// - Parameter url: The URL to check.
	/// - Returns: True if the file exists and is in storage. False otherwise.
	static func contains(_ url: URL) -> Bool {
		guard url.path.hasPrefix("\(directory.path)"),
		      FileManager.default.fileExists(atPath: url.path, isDirectory: nil)
		else {
			return false
		}
		return true
	}
}
