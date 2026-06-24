//
//  LibraryOperationErrorAlert.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

import SwiftUI

extension View {
    func libraryOperationErrorAlert(for library: LibraryModel) -> some View {
        alert(
            "Library Update Failed",
            isPresented: .init(
                get: {
                    library.operationError != nil
                },
                set: { isPresented in
                    if !isPresented {
                        library.clearOperationError()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                library.clearOperationError()
            }
        } message: {
            Text(library.operationError?.message ?? "")
        }
    }
}
