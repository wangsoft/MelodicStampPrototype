//
//  DelegatedPlaylistStateStorage.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/30.
//

import SwiftUI

struct DelegatedPlaylistStateStorage: View {
    @Environment(PlaylistModel.self) private var playlist
    @Environment(PlayerModel.self) private var player

    private var playbackProgressBucket: Int {
        Int((player.playbackTime?.elapsed ?? .zero) / 5)
    }

    var body: some View {
        ZStack {
            stateObservations()
            playbackProgressObservations()
        }
    }

    @ViewBuilder private func stateObservations() -> some View {
        Color.clear
            .onChange(of: playlist.segments.state) { _, _ in
                guard playlist.mode.isCanonical else { return }
                Task {
                    playlist.save(segments: [.state])
                }
            }
    }

    @ViewBuilder private func playbackProgressObservations() -> some View {
        Color.clear
            .onChange(of: playbackProgressBucket) { _, _ in
                guard let elapsedTime = player.playbackTime?.elapsed else { return }
                playlist.updateCurrentTrackElapsedTime(elapsedTime)
            }
            .onChange(of: player.playbackState) { _, _ in
                guard let elapsedTime = player.playbackTime?.elapsed else { return }
                playlist.updateCurrentTrackElapsedTime(elapsedTime)
            }
    }
}
