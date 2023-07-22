//
//  SandboxFileBrowser.swift
//  WalletBase
//
//  Created by Mark Jerde on 7/19/22.
//

import SwiftUI

struct SandboxFileBrowser: View {
	@State private var folder: WalletFile?
	@State private var files: [WalletFile] = []
	let onItemTap: (WalletFile) -> Void
	let browse: () -> Void
	@State private var filtered: Bool = false
	@State private var previousSearch: String?

	init(folder: WalletFile? = nil, files: [WalletFile] = [], onItemTap: @escaping (WalletFile) -> Void, browse: @escaping () -> Void) {
		_folder = .init(initialValue: folder)
		_files = .init(initialValue: files)
		self.onItemTap = onItemTap
		self.browse = browse
		self.filtered = filtered
		self.previousSearch = previousSearch
	}

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
				ItemGrid(items: files,
				         container: folder,
				         emptyMessage: "No filenames match search.",
				         onItemTap: { item in
				         	onItemTap(item)
				         },
				         onBackTap: {
				         	// Folders not supported yet.
				         },
				         onNewTap: nil,
				         onSearch: { searchString in
				         	guard searchString != previousSearch else { return }
				         	previousSearch = searchString
				         	loadFiles(searchString: searchString)
				         })
				#if DEBUG
					.onAppear {
						guard let sample = files.first(where: { $0.name == "Sample.swl" }),
						      !Self.didAutoSelectSampleWallet else { return }
						Self.didAutoSelectSampleWallet = true
						DispatchQueue.main.async {
							self.onItemTap(sample)
						}
					}
				#endif
				Button("Browse") {
					browse()
				}
				.padding(.all, 20)
			}
		}
	}

	#if DEBUG
		static var didAutoSelectSampleWallet = false
	#endif
}

struct SandboxFileBrowser_Previews: PreviewProvider {
	static var previews: some View {
		SandboxFileBrowser(folder: nil,
		                   files: [WalletFile(url: URL(fileURLWithPath: "example.swl"),
		                                      type: .file)]) { _ in
			// No-op
		} browse: {
			// No-op
		}
	}
}
