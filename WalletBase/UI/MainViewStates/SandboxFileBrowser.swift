//
//  SandboxFileBrowser.swift
//  WalletBase
//
//  Created by Mark Jerde on 7/19/22.
//

import SwiftUI

struct SandboxFileBrowser: View {
	@Binding var folder: WalletFile?
	@Binding var files: [WalletFile]
	let onItemTap: (WalletFile) -> Void
	let browse: () -> Void
	@State private var filtered: Bool = false

	fileprivate func loadFiles(searchString: String? = nil) {
		// Look for already-imported files.
		// Only map swl files (no folders) for now.
		let found = FileStorage.items
			.filter { $0.lastPathComponent.hasSuffix(".swl")
			}
			.map { WalletFile(url: $0, type: .file) }

		guard let searchString = searchString,
		      !searchString.isEmpty
		else {
			files = found

			// Open the file dialog if there are no already-imported files.
			if files.isEmpty {
				browse()
			}

			filtered = false
			return
		}

		files = found.filter { file in
			file.url.lastPathComponent.lowercased().contains(searchString.lowercased())
		}
		filtered = true
	}

	var body: some View {
		if files.isEmpty,
		   !filtered
		{
			Text("Loading...")
				.onAppear {
					loadFiles()
				}
		} else {
			VStack {
				ItemGrid(items: $files,
				         container: $folder,
				         emptyMessage: "No filenames match search.") { item in
					onItemTap(item)
				} onBackTap: {
					// Folders not supported yet.
				} onSearch: { searchString in
					loadFiles(searchString: searchString)
				}
				Button("Browse") {
					browse()
				}
				.padding(.all, 20)
			}
		}
	}
}

struct SandboxFileBrowser_Previews: PreviewProvider {
	static var previews: some View {
		SandboxFileBrowser(folder: .constant(nil),
		                   files: .constant([WalletFile(url: URL(fileURLWithPath: "example.swl"),
		                                                type: .file)])) { _ in
			// No-op
		} browse: {
			// No-op
		}
	}
}
