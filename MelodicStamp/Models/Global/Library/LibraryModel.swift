//
//  LibraryModel.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/29.
//

import SwiftUI

extension LibraryModel: TypeNameReflectable {}

struct LibraryOperationError: Identifiable, Equatable {
    let id = UUID()
    var message: String

    static let indexWriteFailed = Self(message: "Could not update the library index.")

    static func deleteFailed(count: Int) -> Self {
        if count == 1 {
            return .init(message: "Could not delete 1 playlist.")
        }
        return .init(message: "Could not delete \(count) playlists.")
    }

    static func == (lhs: LibraryOperationError, rhs: LibraryOperationError) -> Bool {
        lhs.message == rhs.message
    }
}

struct LibraryLoadError: Identifiable, Equatable {
    let id = UUID()
    var failedCount: Int

    static func missingPlaylists(count: Int) -> Self {
        .init(failedCount: count)
    }

    var message: String {
        if failedCount == 1 {
            return "Could not restore 1 playlist from the library."
        }
        return "Could not restore \(failedCount) playlists from the library."
    }

    static func == (lhs: LibraryLoadError, rhs: LibraryLoadError) -> Bool {
        lhs.failedCount == rhs.failedCount
    }
}

@Observable final class LibraryModel {
    private(set) var playlists: [Playlist] = []
    private(set) var indexer: PlaylistIndexer = .init()

    var loadError: LibraryLoadError?
    var operationError: LibraryOperationError?

    private(set) var isLoading: Bool = false
    private(set) var loadingProgress: CGFloat?

    init() {
        loadIndexer()
    }
}

extension LibraryModel: Sequence {
    func makeIterator() -> Array<Playlist>.Iterator {
        playlists.makeIterator()
    }

    var count: Int {
        indexer.value.count
    }

    var loadedPlaylistsCount: Int {
        playlists.count
    }

    var isEmpty: Bool {
        count == 0
    }

    var isLoadedPlaylistsEmpty: Bool {
        loadedPlaylistsCount == 0
    }
}

extension LibraryModel {
    private func captureIndices() -> PlaylistIndexer.Value {
        playlists.map(\.id)
    }

    private func indexPlaylists(with value: PlaylistIndexer.Value) throws {
        indexer.value = value
        try indexer.write()
    }

    @MainActor private func persistPlaylistIndex() -> Bool {
        do {
            try indexPlaylists(with: captureIndices())
            return true
        } catch {
            operationError = .indexWriteFailed
            return false
        }
    }

    func loadIndexer() {
        indexer.value = indexer.read() ?? []
    }

    @MainActor func loadPlaylists(with value: PlaylistIndexer.Value? = nil) async {
        guard !isLoading else { return }
        loadError = nil
        loadingProgress = nil
        isLoading = true
        defer {
            isLoading = false
            loadingProgress = nil
        }

        if let value {
            indexer.value = value
        } else {
            loadIndexer()
        }

        playlists.removeAll()
        guard !indexer.value.isEmpty else { return }

        var loadedCount = 0
        for await (_, playlist) in indexer.loadPlaylists() {
            playlists.append(playlist)
            loadedCount += 1
            loadingProgress = CGFloat(loadedCount) / CGFloat(count)
        }

        let failedCount = Swift.max(0, count - loadedCount)
        if failedCount > 0 {
            loadError = .missingPlaylists(count: failedCount)
        }
    }
}

extension LibraryModel {
    private func deletePlaylist(at url: URL) throws {
        try FileManager.default.removeItem(at: url)

        logger.info("Deleted playlist at \(url)")
    }
}

extension LibraryModel {
    @MainActor func move(fromOffsets indices: IndexSet, toOffset destination: Int) {
        playlists.move(fromOffsets: indices, toOffset: destination)

        if persistPlaylistIndex() {
            operationError = nil
        }
    }

    @MainActor func add(_ playlists: [Playlist], at destination: Int? = nil) {
        let filteredPlaylists = playlists.filter { !self.playlists.contains($0) }

        if let destination, 0...self.playlists.endIndex ~= destination {
            self.playlists.insert(contentsOf: filteredPlaylists, at: destination)
        } else {
            self.playlists.append(contentsOf: filteredPlaylists)
        }

        if persistPlaylistIndex() {
            operationError = nil
        }
    }

    @MainActor func remove(_ playlists: [Playlist]) {
        self.playlists.removeAll(where: playlists.contains)

        let failedDeletionCount = playlists.reduce(into: 0) { count, playlist in
            do {
                try deletePlaylist(at: playlist.url)
            } catch {
                count += 1
            }
        }

        let didPersistIndex = persistPlaylistIndex()
        if failedDeletionCount > 0 {
            operationError = .deleteFailed(count: failedDeletionCount)
        } else if didPersistIndex {
            operationError = nil
        }
    }

    @MainActor func clearOperationError() {
        operationError = nil
    }

    @MainActor func clearLoadError() {
        loadError = nil
    }
}
