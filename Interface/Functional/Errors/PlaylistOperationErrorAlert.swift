//
//  PlaylistOperationErrorAlert.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

import SwiftUI

extension View {
    func playlistOperationErrorAlert(for playlist: PlaylistModel) -> some View {
        alert(
            "Playlist Update Failed",
            isPresented: .init(
                get: {
                    playlist.operationError != nil
                },
                set: { isPresented in
                    if !isPresented {
                        playlist.clearOperationError()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                playlist.clearOperationError()
            }
        } message: {
            Text(playlist.operationError?.message ?? "")
        }
    }
}
