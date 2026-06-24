//
//  MetadataEditorModelSaveErrorTests.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

@testable import MelodicStamp
import CSFBAudioEngine
import Foundation
import Testing

@MainActor @Suite struct MetadataEditorModelSaveErrorTests {
    @Test func recordsSaveErrorWhenBatchWriteFails() async {
        let library = LibraryModel()
        let playlist = PlaylistModel(library: library)
        let url = URL(fileURLWithPath: "/tmp/melodic-stamp-missing-\(UUID().uuidString).mp3")

        let audioMetadata = AudioMetadata()
        audioMetadata.title = "Original"

        let metadata = Metadata(url: url, from: audioMetadata)
        let track = Track(url: url, metadata: metadata)
        playlist.playlist.add([track])
        playlist.selectedTracks = [track]

        metadata.title.current = "Edited"

        let editor = MetadataEditorModel(playlist: playlist)
        await withCheckedContinuation { continuation in
            editor.writeAll {
                continuation.resume()
            }
        }

        #expect(editor.saveError?.failedCount == 1)
        #expect(editor.saveError?.fileNames == [url.lastPathComponent])

        editor.clearSaveError()

        #expect(editor.saveError == nil)
    }
}
