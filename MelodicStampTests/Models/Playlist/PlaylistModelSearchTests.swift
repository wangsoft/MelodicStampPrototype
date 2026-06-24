//
//  PlaylistModelSearchTests.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

@testable import MelodicStamp
import CSFBAudioEngine
import Foundation
import Testing

@MainActor @Suite struct PlaylistModelSearchTests {
    @Test func emptySearchShowsAllTracks() {
        let playlist = makePlaylist()

        playlist.searchText = "   "

        #expect(!playlist.isFiltering)
        #expect(playlist.filteredTracks == playlist.tracks)
    }

    @Test func filtersByTitleArtistAlbumAndFilename() {
        let playlist = makePlaylist()

        playlist.searchText = "night"
        #expect(playlist.filteredTracks.map(\.url.lastPathComponent) == ["first.mp3"])

        playlist.searchText = "second artist"
        #expect(playlist.filteredTracks.map(\.url.lastPathComponent) == ["second.flac"])

        playlist.searchText = "album beta"
        #expect(playlist.filteredTracks.map(\.url.lastPathComponent) == ["second.flac"])

        playlist.searchText = "third"
        #expect(playlist.filteredTracks.map(\.url.lastPathComponent) == ["third.wav"])
    }

    @Test func reportsEmptyFilteredStateWithoutChangingPlaylistContents() {
        let playlist = makePlaylist()

        playlist.searchText = "missing"

        #expect(playlist.isFiltering)
        #expect(playlist.isFilteredTracksEmpty)
        #expect(playlist.tracks.count == 3)
    }

    private func makePlaylist() -> PlaylistModel {
        let playlist = PlaylistModel(library: LibraryModel())
        playlist.playlist = .referenced()
        playlist.playlist.tracks = [
            track(fileName: "first.mp3", title: "Night Drive", artist: "Artist One", album: "Album Alpha"),
            track(fileName: "second.flac", title: "Morning", artist: "Second Artist", album: "Album Beta"),
            track(fileName: "third.wav", title: nil, artist: nil, album: nil)
        ]
        return playlist
    }

    private func track(fileName: String, title: String?, artist: String?, album: String?) -> Track {
        let url = URL(fileURLWithPath: "/tmp/\(fileName)")
        let metadata = AudioMetadata()
        metadata.title = title
        metadata.artist = artist
        metadata.albumTitle = album

        return Track(url: url, metadata: Metadata(url: url, from: metadata))
    }
}
