//
//  MetadataUpdateErrorAlert.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

import SwiftUI

extension View {
    func metadataUpdateErrorAlert(for metadataEditor: MetadataEditorModel) -> some View {
        alert(
            "Metadata Load Failed",
            isPresented: .init(
                get: {
                    metadataEditor.updateError != nil
                },
                set: { isPresented in
                    if !isPresented {
                        metadataEditor.clearUpdateError()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                metadataEditor.clearUpdateError()
            }
        } message: {
            Text(metadataUpdateErrorMessage(metadataEditor.updateError))
        }
    }
}

private func metadataUpdateErrorMessage(_ error: MetadataUpdateError?) -> String {
    guard let error else { return "" }

    let summary: String
    if error.failedCount == 1 {
        summary = "Could not refresh metadata for 1 file."
    } else {
        summary = "Could not refresh metadata for \(error.failedCount) files."
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
