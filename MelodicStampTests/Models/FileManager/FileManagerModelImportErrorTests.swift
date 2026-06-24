//
//  FileManagerModelImportErrorTests.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

@testable import MelodicStamp
import Foundation
import Testing

@MainActor @Suite struct FileManagerModelImportErrorTests {
    @Test func recordsImportErrorWhenOpenURLIsUnavailable() {
        let model = makeModel()
        let url = URL(fileURLWithPath: "/tmp/melodic-stamp-missing-\(UUID().uuidString).mp3")

        #expect(model.resolvedOpenURL(url) == nil)
        #expect(model.importError?.message == "Could not access \(url.lastPathComponent).")

        model.clearImportError()

        #expect(model.importError == nil)
    }

    @Test func recordsImportErrorWhenAddedSelectionHasNoSupportedAudioFiles() throws {
        let model = makeModel()
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("melodic-stamp-empty-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: folder)
        }

        let textFile = folder.appendingPathComponent("notes.txt")
        try "not audio".write(to: textFile, atomically: true, encoding: .utf8)

        #expect(model.resolvedAddedURLs([folder]).isEmpty)
        #expect(model.importError?.message == "No supported audio files were found.")
    }

    private func makeModel() -> FileManagerModel {
        let library = LibraryModel()
        let playlist = PlaylistModel(library: library)
        let player = PlayerModel(BlankPlayer(), library: library, playlist: playlist)
        return FileManagerModel(player: player, playlist: playlist)
    }
}
