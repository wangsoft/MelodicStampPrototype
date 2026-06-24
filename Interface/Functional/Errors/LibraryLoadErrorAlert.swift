//
//  LibraryLoadErrorAlert.swift
//  Melodic Stamp
//
//  Created by OpenAI on 2026/6/22.
//

import SwiftUI

extension View {
    func libraryLoadErrorAlert(for library: LibraryModel) -> some View {
        alert(
            "Library Restore Failed",
            isPresented: .init(
                get: {
                    library.loadError != nil
                },
                set: { isPresented in
                    if !isPresented {
                        library.clearLoadError()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                library.clearLoadError()
            }
        } message: {
            Text(library.loadError?.message ?? "")
        }
    }
}
