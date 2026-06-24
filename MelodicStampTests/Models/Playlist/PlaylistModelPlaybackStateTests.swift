//
//  PlaylistModelPlaybackStateTests.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

@testable import MelodicStamp
import CSFBAudioEngine
import Foundation
import Testing

@MainActor @Suite struct PlaylistModelPlaybackStateTests {
    @Test func restoresCurrentTrackFromPlaybackStateURL() {
        let playlist = PlaylistModel(library: LibraryModel())
        let firstTrack = track(fileName: "first.mp3")
        let secondTrack = track(fileName: "second.flac")
        playlist.playlist.tracks = [firstTrack, secondTrack]

        playlist.restorePlaybackState(.init(
            currentTrackURL: secondTrack.url,
            currentTrackElapsedTime: 42,
            playbackMode: .shuffle,
            playbackLooping: true
        ))

        #expect(playlist.currentTrack == secondTrack)
        #expect(playlist.segments.state.currentTrackURL == secondTrack.url)
        #expect(playlist.segments.state.currentTrackElapsedTime == 42)
        #expect(playlist.playbackMode == .shuffle)
        #expect(playlist.playbackLooping)
    }

    @Test func updateCurrentTrackElapsedTimeIgnoresNegativeValues() {
        let playlist = PlaylistModel(library: LibraryModel())
        let currentTrack = track(fileName: "current.mp3")
        playlist.playlist.tracks = [currentTrack]
        playlist.currentTrack = currentTrack

        playlist.updateCurrentTrackElapsedTime(-10)

        #expect(playlist.segments.state.currentTrackElapsedTime == 0)
    }

    @Test func selectingTrackResetsSavedElapsedTime() async {
        let playlist = PlaylistModel(library: LibraryModel())
        let selectedTrack = track(fileName: "selected.mp3")
        playlist.playlist.tracks = [selectedTrack]
        playlist.segments.state.currentTrackElapsedTime = 120

        _ = await playlist.play(selectedTrack.url)

        #expect(playlist.currentTrack == selectedTrack)
        #expect(playlist.segments.state.currentTrackElapsedTime == 0)
    }

    private func track(fileName: String) -> Track {
        let url = URL(fileURLWithPath: "/tmp/\(fileName)")
        return Track(url: url, metadata: Metadata(url: url, from: AudioMetadata()))
    }
}
