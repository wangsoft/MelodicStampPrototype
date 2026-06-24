//
//  FileImportErrorAlert.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

import SwiftUI

extension View {
    func fileImportErrorAlert(for fileManager: FileManagerModel) -> some View {
        alert(
            "File Import Failed",
            isPresented: .init(
                get: {
                    fileManager.importError != nil
                },
                set: { isPresented in
                    if !isPresented {
                        fileManager.clearImportError()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                fileManager.clearImportError()
            }
        } message: {
            Text(fileManager.importError?.message ?? "")
        }
    }
}
