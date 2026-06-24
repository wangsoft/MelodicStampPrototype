//
//  PlaylistModelOperationErrorTests.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

@testable import MelodicStamp
import CSFBAudioEngine
import Foundation
import Testing

@MainActor @Suite struct PlaylistModelOperationErrorTests {
    @Test func recordsOperationErrorWhenPlaylistSegmentSaveFails() async throws {
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
        try FileManager.default.removeItem(at: url)
        try Data("not a directory".utf8).write(to: url)

        playlist.save(segments: [.info])

        #expect(playlist.operationError?.message == "Could not save playlist information.")

        playlist.clearOperationError()

        #expect(playlist.operationError == nil)
    }

    @Test func recordsOperationErrorWhenTrackIndexWriteFails() async throws {
        let id = UUID()
        let url = Playlist.url(forID: id)
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        guard var canonicalPlaylist = try await Playlist(makingCanonical: .referenced(bindingTo: id)) else {
            Issue.record("Expected canonical playlist creation to succeed")
            return
        }

        let firstURL = URL(fileURLWithPath: "/tmp/melodic-stamp-\(UUID().uuidString)-1.mp3")
        let secondURL = URL(fileURLWithPath: "/tmp/melodic-stamp-\(UUID().uuidString)-2.mp3")
        canonicalPlaylist.tracks = [
            Track(url: firstURL, metadata: Metadata(url: firstURL, from: AudioMetadata())),
            Track(url: secondURL, metadata: Metadata(url: secondURL, from: AudioMetadata()))
        ]

        let playlist = PlaylistModel(bindingTo: id, library: LibraryModel())
        playlist.playlist = canonicalPlaylist
        try FileManager.default.removeItem(at: url)
        try Data("not a directory".utf8).write(to: url)

        playlist.move(fromOffsets: IndexSet(integer: 0), toOffset: 1)

        #expect(playlist.operationError?.message == "Could not update the playlist track order.")
    }
}
