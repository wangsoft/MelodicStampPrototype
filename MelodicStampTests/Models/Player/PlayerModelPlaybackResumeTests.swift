//
//  PlayerModelPlaybackResumeTests.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

@testable import MelodicStamp
import CSFBAudioEngine
import Foundation
import Testing

@MainActor @Suite struct PlayerModelPlaybackResumeTests {
    final class PlaybackResumePlayer: BlankPlayer {
        var playedTracks: [Track] = []
        var soughtTimes: [TimeInterval] = []

        override func play(_ track: Track) {
            playedTracks.append(track)
            super.play(track)
        }

        override func seekTime(to time: TimeInterval) {
            soughtTimes.append(time)
            super.seekTime(to: time)
        }
    }

    @Test func playRestoresSavedElapsedTimeForRestoredCurrentTrack() {
        let library = LibraryModel()
        let playlist = PlaylistModel(library: library)
        let restoredTrack = track(fileName: "restored.flac")
        playlist.playlist.tracks = [restoredTrack]
        playlist.restorePlaybackState(.init(
            currentTrackURL: restoredTrack.url,
            currentTrackElapsedTime: 42,
            playbackMode: .loop,
            playbackLooping: false
        ))

        let spyPlayer = PlaybackResumePlayer()
        let player = PlayerModel(spyPlayer, library: library, playlist: playlist)

        player.play()

        #expect(spyPlayer.playedTracks == [restoredTrack])
        #expect(spyPlayer.soughtTimes == [42])
        #expect(player.playbackTime?.elapsed == 42)
        #expect(playlist.segments.state.currentTrackElapsedTime == 42)
    }

    @Test func playClearsSavedElapsedTimeWhenTrackChanges() {
        let library = LibraryModel()
        let playlist = PlaylistModel(library: library)
        let previousTrack = track(fileName: "previous.flac")
        let nextTrack = track(fileName: "next.flac")
        playlist.playlist.tracks = [previousTrack, nextTrack]
        playlist.restorePlaybackState(.init(
            currentTrackURL: previousTrack.url,
            currentTrackElapsedTime: 42,
            playbackMode: .loop,
            playbackLooping: false
        ))

        let spyPlayer = PlaybackResumePlayer()
        let player = PlayerModel(spyPlayer, library: library, playlist: playlist)

        player.play(nextTrack)

        #expect(spyPlayer.playedTracks == [nextTrack])
        #expect(spyPlayer.soughtTimes.isEmpty)
        #expect(playlist.currentTrack == nextTrack)
        #expect(playlist.segments.state.currentTrackElapsedTime == 0)
    }

    private func track(fileName: String) -> Track {
        let url = URL(fileURLWithPath: "/tmp/\(fileName)")
        return Track(url: url, metadata: Metadata(url: url, from: AudioMetadata()))
    }
}
