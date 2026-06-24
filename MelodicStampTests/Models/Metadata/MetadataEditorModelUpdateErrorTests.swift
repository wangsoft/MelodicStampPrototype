//
//  MetadataEditorModelUpdateErrorTests.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

@testable import MelodicStamp
import CSFBAudioEngine
import Foundation
import Testing

@MainActor @Suite struct MetadataEditorModelUpdateErrorTests {
    @Test func recordsUpdateErrorWhenBatchRefreshFails() async {
        let library = LibraryModel()
        let playlist = PlaylistModel(library: library)
        let url = URL(fileURLWithPath: "/tmp/melodic-stamp-missing-\(UUID().uuidString).mp3")

        let audioMetadata = AudioMetadata()
        audioMetadata.title = "Original"

        let metadata = Metadata(url: url, from: audioMetadata)
        let track = Track(url: url, metadata: metadata)
        playlist.playlist.add([track])
        playlist.selectedTracks = [track]

        let editor = MetadataEditorModel(playlist: playlist)
        await withCheckedContinuation { continuation in
            editor.updateAll {
                continuation.resume()
            }
        }

        #expect(editor.updateError?.failedCount == 1)
        #expect(editor.updateError?.fileNames == [url.lastPathComponent])

        editor.clearUpdateError()

        #expect(editor.updateError == nil)
    }
}
