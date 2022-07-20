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

	var body: some View {
		if files.isEmpty {
			Text("Loading...")
				.onAppear {
					// Look for already-imported files.
					// Only map swl files (no folders) for now.
					files = FileStorage.items
						.filter { $0.lastPathComponent.hasSuffix(".swl")
						}
						.map { WalletFile(url: $0, type: .file) }

					// Open the file dialog if there are no already-imported files.
					if files.isEmpty {
						browse()
					}
				}
		} else {
			VStack {
				ItemGrid(items: $files, container: $folder) { item in
					onItemTap(item)
				} onBackTap: {
					// Folders not supported yet.
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
