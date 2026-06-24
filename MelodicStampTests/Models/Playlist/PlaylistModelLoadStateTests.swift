//
//  PlaylistModelLoadStateTests.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

@testable import MelodicStamp
import Collections
import Foundation
import Testing

@MainActor @Suite struct PlaylistModelLoadStateTests {
    @Test func loadingEmptyCanonicalPlaylistResetsLoadingState() async throws {
        let id = UUID()
        let url = Playlist.url(forID: id)
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        guard let canonicalPlaylist = try await Playlist(makingCanonical: .referenced(bindingTo: id)) else {
            Issue.record("Expected canonical playlist creation to succeed")
            return
        }

        let playlist = PlaylistModel(bindingTo: id, library: LibraryModel())
        playlist.playlist = canonicalPlaylist

        await playlist.loadTracks()

        #expect(playlist.isLoading == false)
        #expect(playlist.loadingProgress == nil)
        #expect(playlist.loadError == nil)
    }

    @Test func recordsLoadErrorWhenIndexedTracksCannotBeRestored() async throws {
        let id = UUID()
        let url = Playlist.url(forID: id)
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        guard var canonicalPlaylist = try await Playlist(makingCanonical: .referenced(bindingTo: id)) else {
            Issue.record("Expected canonical playlist creation to succeed")
            return
        }
        canonicalPlaylist.indexer.value = OrderedDictionary(uniqueKeysWithValues: [
            (UUID(), "mp3"),
            (UUID(), "flac")
        ])
        try canonicalPlaylist.indexer.write()

        let playlist = PlaylistModel(bindingTo: id, library: LibraryModel())
        playlist.playlist = canonicalPlaylist

        await playlist.loadTracks()

        #expect(playlist.isLoading == false)
        #expect(playlist.loadingProgress == nil)
        #expect(playlist.loadError?.message == "Could not restore 2 tracks from the playlist.")
        #expect(playlist.tracks.isEmpty)

        playlist.clearLoadError()
        #expect(playlist.loadError == nil)
    }
}
