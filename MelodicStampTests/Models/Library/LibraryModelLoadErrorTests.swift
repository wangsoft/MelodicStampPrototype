//
//  LibraryModelLoadErrorTests.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

@testable import MelodicStamp
import Foundation
import Testing

@MainActor @Suite struct LibraryModelLoadErrorTests {
    @Test func loadingEmptyLibraryResetsLoadingState() async {
        let library = LibraryModel()

        await library.loadPlaylists(with: [])

        #expect(library.isLoading == false)
        #expect(library.loadingProgress == nil)
        #expect(library.loadError == nil)
        #expect(library.playlists.isEmpty)
    }

    @Test func recordsLoadErrorWhenPlaylistsCannotBeRestored() async {
        let library = LibraryModel()

        await library.loadPlaylists(with: [UUID(), UUID()])

        #expect(library.isLoading == false)
        #expect(library.loadingProgress == nil)
        #expect(library.loadError?.message == "Could not restore 2 playlists from the library.")
        #expect(library.playlists.isEmpty)
    }
}
