//
//  MetadataSaveErrorAlert.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

import SwiftUI

extension View {
    func metadataSaveErrorAlert(for metadataEditor: MetadataEditorModel) -> some View {
        alert(
            "Metadata Save Failed",
            isPresented: .init(
                get: {
                    metadataEditor.saveError != nil
                },
                set: { isPresented in
                    if !isPresented {
                        metadataEditor.clearSaveError()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                metadataEditor.clearSaveError()
            }
        } message: {
            Text(metadataSaveErrorMessage(metadataEditor.saveError))
        }
    }
}

private func metadataSaveErrorMessage(_ error: MetadataSaveError?) -> String {
    guard let error else { return "" }

    let summary: String
    if error.failedCount == 1 {
        summary = "Could not save metadata for 1 file."
    } else {
        summary = "Could not save metadata for \(error.failedCount) files."
    }

    let visibleFileNames = error.fileNames.prefix(5)
    guard !visibleFileNames.isEmpty else {
        return summary
    }

    var lines = [summary, "", visibleFileNames.joined(separator: "\n")]
    let hiddenCount = error.failedCount - visibleFileNames.count
    if hiddenCount > 0 {
        lines.append("...and \(hiddenCount) more.")
    }

    return lines.joined(separator: "\n")
}
