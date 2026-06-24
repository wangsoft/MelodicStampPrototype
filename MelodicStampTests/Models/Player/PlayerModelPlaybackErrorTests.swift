//
//  PlayerModelPlaybackErrorTests.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

@testable import MelodicStamp
import SFBAudioEngine
import Testing

@MainActor @Suite struct PlayerModelPlaybackErrorTests {
    enum TestPlaybackError: LocalizedError {
        case decoderFailed

        var errorDescription: String? {
            "Decoder failed"
        }
    }

    @Test func recordsPlaybackErrorReportedByAudioEngine() async {
        let library = LibraryModel()
        let playlist = PlaylistModel(library: library)
        let player = PlayerModel(BlankPlayer(), library: library, playlist: playlist)

        player.audioPlayer(AudioPlayer(), encounteredError: TestPlaybackError.decoderFailed)
        await Task.yield()

        #expect(player.playbackError?.message == "Decoder failed")

        player.clearPlaybackError()

        #expect(player.playbackError == nil)
    }
}
