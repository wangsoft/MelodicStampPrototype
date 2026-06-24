//
//  PlaylistLoadErrorAlert.swift
//  Melodic Stamp
//
//  Created by OpenAI on 2026/6/22.
//

import SwiftUI

extension View {
    func playlistLoadErrorAlert(for playlist: PlaylistModel) -> some View {
        alert(
            "Playlist Restore Failed",
            isPresented: .init(
                get: {
                    playlist.loadError != nil
                },
                set: { isPresented in
                    if !isPresented {
                        playlist.clearLoadError()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                playlist.clearLoadError()
            }
        } message: {
            Text(playlist.loadError?.message ?? "")
        }
    }
}
