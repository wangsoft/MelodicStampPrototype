//
//  Playlist.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/27.
//

import AppKit
import Defaults
import Foundation

extension Playlist: TypeNameReflectable {}

extension Playlist {
    enum Mode: String, Equatable, Hashable, CaseIterable, Identifiable, Codable {
        case referenced
        case canonical

        var id: Self { self }

        var isCanonical: Bool {
            switch self {
            case .canonical:
                true
            default:
                false
            }
        }
    }
}

struct Playlist: Equatable, Hashable, Identifiable {
    let id: UUID
    let mode: Mode
    var segments: Segments

    var tracks: [Track] = []
    var indexer: TrackIndexer

    // Delegated variables
    // Must not have inlined getters and setters, otherwise causing UI glitches

    var currentTrack: Track? {
        didSet {
            segments.state.currentTrackURL = currentTrack?.url
        }
    }

    private mutating func loadDelegatedVariables() {
        currentTrack = tracks.first { $0.url == segments.state.currentTrackURL }
    }

    var url: URL {
        Self.url(forID: id)
    }

    var unwrappedURL: URL? {
        switch mode {
        case .referenced:
            nil
        case .canonical:
            url
        }
    }

    var canMakeCanonical: Bool {
        !mode.isCanonical && !tracks.isEmpty
    }

    private init(
        id: UUID,
        mode: Mode,
        segments: Segments
    ) {
        self.id = id
        self.mode = mode
        self.segments = segments
        self.indexer = .init(playlistID: id)
    }

    init?(loadingWith id: UUID) {
        let url = Self.url(forID: id)
        guard let segments = try? Segments(loadingFrom: url) else { return nil }
        self.init(id: id, mode: .canonical, segments: segments)
        loadDelegatedVariables()
        loadIndexer()

        logger.info("Loaded canonical playlist from \(url)")
    }

    init?(copyingFrom playlist: Playlist) throws {
        guard playlist.mode.isCanonical else { return nil }

        let playlistID = UUID()
        try FileManager.default.copyItem(at: playlist.url, to: Self.url(forID: playlistID))

        self.init(loadingWith: playlistID)
    }

    init?(makingCanonical oldValue: Playlist) async throws {
        do {
            try FileManager.default.createDirectory(at: oldValue.url, withIntermediateDirectories: true)
        } catch {
            return nil
        }

        self.init(id: oldValue.id, mode: .canonical, segments: oldValue.segments)
        self.tracks = oldValue.tracks

        var migratedCurrentTrackURL: URL?
        for (index, track) in tracks.enumerated() {
            guard let migratedTrack = try? await migrateTrack(from: track) else { continue }
            tracks[index] = migratedTrack

            let wasCurrentTrack = track.url == segments.state.currentTrackURL
            if wasCurrentTrack {
                migratedCurrentTrackURL = migratedTrack.url
            }
        }

        segments.state.currentTrackURL = migratedCurrentTrackURL

        try write()
        loadDelegatedVariables()

        logger.info("Successfully made canonical playlist at \(oldValue.url)")
    }

    static func referenced(bindingTo id: UUID = .init()) -> Playlist {
        .init(
            id: id,
            mode: .referenced,
            segments: .init()
        )
    }
}

extension Playlist: Sequence {
    func makeIterator() -> Array<Track>.Iterator {
        tracks.makeIterator()
    }

    var count: Int {
        switch mode {
        case .referenced:
            loadedTracksCount
        case .canonical:
            indexer.value.count
        }
    }

    var loadedTracksCount: Int {
        tracks.count
    }

    var isEmpty: Bool {
        count == 0
    }

    var isLoadedTracksEmpty: Bool {
        loadedTracksCount == 0
    }
}

extension Playlist {
    static func url(forID id: UUID) -> URL {
        URL.playlists.appending(component: id.uuidString, directoryHint: .isDirectory)
    }
}

extension Playlist {
    mutating func loadIndexer() {
        guard mode.isCanonical else { return }
        indexer.value = indexer.read() ?? [:]
    }
}

extension Playlist {
    func write(segments: [Playlist.Segment] = Playlist.Segment.allCases) throws {
        guard !segments.isEmpty, let url = unwrappedURL else { return }

        for segment in segments {
            let data = switch segment {
            case .info:
                try JSONEncoder().encode(self.segments.info)
            case .state:
                try JSONEncoder().encode(self.segments.state)
            case .artwork:
                try JSONEncoder().encode(self.segments.artwork)
            }
            try Segments.write(segment: segment, ofData: data, toDirectory: url)
        }

        logger.info("Successfully written playlist segments \(segments) for playlist at \(url)")

        // Update workspace related things

        if segments.contains(.artwork) {
            updateFolderIcon()
        }
    }

    private func updateFolderIcon() {
        Task.detached(priority: .background) {
            NSWorkspace.shared.setIcon(
                segments.artwork.image?.squared(),
                forFile: url.standardizedFileURL.path(percentEncoded: false)
            )
            logger.info("Successfully updated folder icon for playlist at \(url)")
        }
    }
}

extension Playlist {
    var nextTrack: Track? {
        guard let nextIndex else { return nil }
        return tracks[nextIndex]
    }

    var previousTrack: Track? {
        guard let previousIndex else { return nil }
        return tracks[previousIndex]
    }

    var hasCurrentTrack: Bool {
        currentTrack != nil
    }

    var hasNextTrack: Bool {
        nextTrack != nil
    }

    var hasPreviousTrack: Bool {
        previousTrack != nil
    }

    private var currentIndex: Int? {
        guard let currentTrack else { return nil }
        return tracks.firstIndex(of: currentTrack)
    }

    private var nextIndex: Int? {
        switch segments.state.playbackMode {
        case .sequential:
            guard let currentIndex else { return nil }
            let nextIndex = currentIndex + 1

            guard nextIndex < tracks.endIndex else { return nil }
            return nextIndex
        case .loop:
            guard let currentIndex else { return nil }
            return (currentIndex + 1) % tracks.count
        case .shuffle:
            return randomIndex()
        }
    }

    private var previousIndex: Int? {
        switch segments.state.playbackMode {
        case .sequential:
            guard let currentIndex else { return nil }
            let previousIndex = currentIndex - 1

            guard previousIndex >= 0 else { return nil }
            return previousIndex
        case .loop:
            guard let currentIndex else { return nil }
            return (currentIndex + tracks.count - 1) % tracks.count
        case .shuffle:
            return randomIndex()
        }
    }

    func randomIndex() -> Int? {
        guard !tracks.isEmpty else { return nil }

        if let currentTrack, let index = tracks.firstIndex(of: currentTrack) {
            let indices = Array(tracks.indices).filter { $0 != index }
            return indices.randomElement()
        } else {
            return tracks.indices.randomElement()
        }
    }
}

extension Playlist {
    private mutating func deleteTrack(at url: URL) throws {
        try FileManager.default.removeItem(at: url)

        logger.info("Deleted canonical track at \(url)")
    }

    private func createFolder() throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func generateCanonicalURL(for url: URL) -> URL {
        let trackID = UUID()
        return self.url
            .appending(component: trackID.uuidString, directoryHint: .notDirectory)
            .appendingPathExtension(url.pathExtension)
    }

    private func migrateTrack(from track: Track) async throws -> Track {
        try createFolder()

        let destinationURL = generateCanonicalURL(for: track.url)
        guard let _: Void = try track.url.withSecurityScopedAccess({ scopedURL in
            try FileManager.default.copyItem(at: scopedURL, to: destinationURL)
        }) else {
            throw CocoaError(.fileReadNoPermission)
        }

        logger.info("Migrating to canonical track at \(destinationURL), copying from \(track.url)")
        return try await Track(
            migratingFrom: track, to: destinationURL,
            useFallbackTitleIfNotProvided: true
        )
    }

    func getTrack(at url: URL) -> Track? {
        first(where: { $0.url == url })
    }

    func createTrack(from url: URL) async -> Track? {
        await withCheckedContinuation { continuation in
            Task {
                switch mode {
                case .referenced:
                    await continuation.resume(returning: Track(loadingFrom: url))
                case .canonical:
                    // 1. Wait for the track to load
                    var track: Track?

                    // 2. Set the loaded track
                    track = await Track(loadingFrom: url, completion: {
                        // Completed reading metadata
                        // 3. Check if the track exists
                        guard let track else { return continuation.resume(returning: nil) }

                        Task {
                            // 4. Migrate the track and return
                            let migratedTrack = try? await self.migrateTrack(from: track)
                            continuation.resume(returning: migratedTrack)
                        }
                    })
                }
            }
        }
    }

    func getOrCreateTrack(at url: URL) async -> Track? {
        if let track = getTrack(at: url) {
            track
        } else {
            await createTrack(from: url)
        }
    }
}

extension Playlist {
    mutating func move(fromOffsets indices: IndexSet, toOffset destination: Int) {
        tracks.move(fromOffsets: indices, toOffset: destination)
    }

    mutating func add(_ tracks: [Track], at destination: Int? = nil) {
        let filteredTracks = tracks.filter { !self.tracks.contains($0) }

        if let destination, 0...self.tracks.endIndex ~= destination {
            self.tracks.insert(contentsOf: filteredTracks, at: destination)
        } else {
            self.tracks.append(contentsOf: filteredTracks)
        }
    }

    mutating func remove(_ tracks: [Track]) {
        if let currentTrack, tracks.contains(currentTrack) {
            self.currentTrack = nil
        }
        self.tracks.removeAll(where: tracks.contains)

        guard mode.isCanonical else { return }
        tracks.forEach { try? deleteTrack(at: $0.url) }
    }

    mutating func clearPlaylist() {
        remove(tracks)
    }
}
