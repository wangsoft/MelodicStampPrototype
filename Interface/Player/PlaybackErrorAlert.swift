//
//  PlaybackErrorAlert.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

import SwiftUI

extension View {
    func playbackErrorAlert(for player: PlayerModel) -> some View {
        alert(
            "Playback Error",
            isPresented: .init(
                get: {
                    player.playbackError != nil
                },
                set: { isPresented in
                    if !isPresented {
                        player.clearPlaybackError()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                player.clearPlaybackError()
            }
        } message: {
            Text(player.playbackError?.message ?? "")
        }
    }
}
