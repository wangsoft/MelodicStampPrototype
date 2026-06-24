//
//  LyricsTextFileLoaderTests.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

import Foundation
@testable import MelodicStamp
import Testing

@Suite struct LyricsTextFileLoaderTests {
    @Test func loadsUTF8LyricsFile() throws {
        let url = temporaryURL(fileName: "lyrics.lrc")
        try "[00:01.00]Line one".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let content = try LyricsTextFileLoader().load(from: url)

        #expect(content == "[00:01.00]Line one")
    }

    @Test func reportsUnreadableNonUTF8File() throws {
        let url = temporaryURL(fileName: "lyrics.bin")
        try Data([0xff, 0xfe, 0xfd]).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            _ = try LyricsTextFileLoader().load(from: url)
            Issue.record("Expected non-UTF-8 file to fail")
        } catch let error as LyricsTextFileLoader.LoadError {
            guard case let .unreadable(failedURL, _) = error else {
                Issue.record("Expected unreadable error, got \(error)")
                return
            }
            #expect(failedURL == url)
        }
    }

    @Test func reportsUnreadableMissingFile() throws {
        let url = temporaryURL(fileName: "missing.lrc")
        try? FileManager.default.removeItem(at: url)

        do {
            _ = try LyricsTextFileLoader().load(from: url)
            Issue.record("Expected missing file to fail")
        } catch let error as LyricsTextFileLoader.LoadError {
            guard case let .unreadable(failedURL, _) = error else {
                Issue.record("Expected unreadable error, got \(error)")
                return
            }
            #expect(failedURL == url)
        }
    }

    private func temporaryURL(fileName: String) -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(fileName)
    }
}
