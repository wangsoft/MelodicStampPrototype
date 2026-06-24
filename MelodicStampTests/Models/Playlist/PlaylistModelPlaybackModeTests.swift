//
//  PlaylistModelPlaybackModeTests.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

@testable import MelodicStamp
import Testing

@MainActor @Suite struct PlaylistModelPlaybackModeTests {
    @Test func changingPlaybackModeClearsSingleTrackRepeat() {
        let playlist = PlaylistModel(library: LibraryModel())
        playlist.playbackMode = .loop
        playlist.playbackLooping = true

        playlist.setPlaybackMode(.shuffle)

        #expect(playlist.playbackMode == .shuffle)
        #expect(!playlist.playbackLooping)
        #expect(playlist.playbackRepeatMode == .off)
    }

    @Test func cyclingPlaybackModeClearsSingleTrackRepeat() {
        let playlist = PlaylistModel(library: LibraryModel())
        playlist.playbackMode = .loop
        playlist.playbackLooping = true

        playlist.cyclePlaybackMode()

        #expect(playlist.playbackMode == .shuffle)
        #expect(!playlist.playbackLooping)
        #expect(playlist.playbackRepeatMode == .off)
    }

    @Test func repeatButtonCyclesOffListSingleAndBackOff() {
        let playlist = PlaylistModel(library: LibraryModel())
        playlist.playbackMode = .sequential
        playlist.playbackLooping = false

        #expect(playlist.playbackRepeatMode == .off)

        playlist.cyclePlaybackRepeatMode()
        #expect(playlist.playbackMode == .loop)
        #expect(!playlist.playbackLooping)
        #expect(playlist.playbackRepeatMode == .list)

        playlist.cyclePlaybackRepeatMode()
        #expect(playlist.playbackMode == .loop)
        #expect(playlist.playbackLooping)
        #expect(playlist.playbackRepeatMode == .single)

        playlist.cyclePlaybackRepeatMode()
        #expect(playlist.playbackMode == .sequential)
        #expect(!playlist.playbackLooping)
        #expect(playlist.playbackRepeatMode == .off)
    }
}
