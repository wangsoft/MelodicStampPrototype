//
//  PlaylistIndexer.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/29.
//

import Foundation

struct PlaylistIndexer: Indexer {
    var folderURL: URL { .playlists }

    var value: [UUID] = []
}

extension PlaylistIndexer {
    func loadPlaylists() -> AsyncStream<(Int, Playlist)> {
        .init {
            continuation in
            guard !value.isEmpty else { return continuation.finish() }

            Task.detached {
                for (index, element) in value.enumerated() {
                    guard let playlist = Playlist(loadingWith: element) else { continue }
                    continuation.yield((index, playlist))
                }
                continuation.finish()
            }
        }
    }
}
