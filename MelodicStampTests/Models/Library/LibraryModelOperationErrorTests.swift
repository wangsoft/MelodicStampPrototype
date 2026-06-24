//
//  LibraryModelOperationErrorTests.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

@testable import MelodicStamp
import Foundation
import Testing

@MainActor @Suite struct LibraryModelOperationErrorTests {
    @Test func recordsOperationErrorWhenLibraryIndexWriteFails() throws {
        let indexURL = PlaylistIndexer().url
        let originalIndexData = try? Data(contentsOf: indexURL)
        defer {
            try? FileManager.default.removeItem(at: indexURL)
            if let originalIndexData {
                try? FileManager.default.createDirectory(at: indexURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? originalIndexData.write(to: indexURL)
            }
        }

        try? FileManager.default.removeItem(at: indexURL)
        try FileManager.default.createDirectory(at: indexURL, withIntermediateDirectories: true)

        let library = LibraryModel()
        library.add([.referenced(bindingTo: UUID())])

        #expect(library.operationError?.message == "Could not update the library index.")

        library.clearOperationError()

        #expect(library.operationError == nil)
    }

    @Test func recordsOperationErrorWhenPlaylistDeletionFails() async throws {
        let indexURL = PlaylistIndexer().url
        let originalIndexData = try? Data(contentsOf: indexURL)
        let id = UUID()
        let playlistURL = Playlist.url(forID: id)
        defer {
            try? FileManager.default.removeItem(at: playlistURL)
            try? FileManager.default.removeItem(at: indexURL)
            if let originalIndexData {
                try? FileManager.default.createDirectory(at: indexURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? originalIndexData.write(to: indexURL)
            }
        }

        guard let playlist = try await Playlist(makingCanonical: .referenced(bindingTo: id)) else {
            Issue.record("Expected canonical playlist creation to succeed")
            return
        }

        let library = LibraryModel()
        library.add([playlist])
        try FileManager.default.removeItem(at: playlistURL)

        library.remove([playlist])

        #expect(library.operationError?.message == "Could not delete 1 playlist.")
    }
}
