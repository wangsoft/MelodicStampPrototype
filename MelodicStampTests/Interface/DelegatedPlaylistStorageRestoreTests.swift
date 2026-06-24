//
//  DelegatedPlaylistStorageRestoreTests.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

@testable import MelodicStamp
import Foundation
import Testing

@Suite struct DelegatedPlaylistStorageRestoreTests {
    @Test func restoresReachableBookmarksAndCountsFailures() throws {
        let fileManager = FileManager.default
        let file = fileManager.temporaryDirectory
            .appendingPathComponent("melodic-stamp-bookmark-\(UUID().uuidString).mp3")
        defer {
            try? fileManager.removeItem(at: file)
        }

        try Data().write(to: file)

        let validBookmark = try file.bookmarkData(options: [.withSecurityScope])
        let invalidBookmark = Data("invalid bookmark".utf8)

        let result = DelegatedPlaylistStorage.restoreReferencedBookmarks(from: [validBookmark, invalidBookmark])

        #expect(result.urls.count == 1)
        #expect(result.urls.first?.lastPathComponent == file.lastPathComponent)
        #expect(result.failedBookmarkCount == 1)
    }
}
