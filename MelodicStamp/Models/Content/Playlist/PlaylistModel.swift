//
//  PlaylistModel.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/31.
//

import Collections
import SwiftUI

struct PlaylistOperationError: Identifiable, Equatable {
    let id = UUID()
    var message: String

    static func saveFailed(segments: [Playlist.Segment]) -> Self {
        if segments == [.info] {
            return .init(message: "Could not save playlist information.")
        }
        if segments == [.artwork] {
            return .init(message: "Could not save playlist artwork.")
        }
        if segments == [.state] {
            return .init(message: "Could not save playlist playback state.")
        }
        return .init(message: "Could not save playlist.")
    }

    static func trackIndexFailed(message: String) -> Self {
        .init(message: message)
    }

    static func == (lhs: PlaylistOperationError, rhs: PlaylistOperationError) -> Bool {
        lhs.message == rhs.message
    }
}

struct PlaylistLoadError: Identifiable, Equatable {
    let id = UUID()
    var failedCount: Int

    static func missingTracks(count: Int) -> Self {
        .init(failedCount: count)
    }

    var message: String {
        if failedCount == 1 {
            return "Could not restore 1 track from the playlist."
        }
        return "Could not restore \(failedCount) tracks from the playlist."
    }

    static func == (lhs: PlaylistLoadError, rhs: PlaylistLoadError) -> Bool {
        lhs.failedCount == rhs.failedCount
    }
}

@Observable final class PlaylistModel {
    #if DEBUG
        var playlist: Playlist
    #else
        private(set) var playlist: Playlist
    #endif
    private weak var library: LibraryModel?

    var selectedTracks: Set<Track> = []
    var saveError: MetadataSaveError?
    var updateError: MetadataUpdateError?
    var loadError: PlaylistLoadError?
    var operationError: PlaylistOperationError?
    var searchText: String = ""

    private(set) var isLoading: Bool = false
    private(set) var loadingProgress: CGFloat?

    init(bindingTo id: UUID = .init(), library: LibraryModel) {
        self.playlist = .referenced(bindingTo: id)
        self.library = library
    }
}

extension PlaylistModel {
    var id: UUID { playlist.id }
    var mode: Playlist.Mode { playlist.mode }
    var tracks: [Track] { playlist.tracks }

    var url: URL { playlist.url }
    var unwrappedURL: URL? { playlist.unwrappedURL }

    var currentTrack: Track? {
        get { playlist.currentTrack }
        set { playlist.currentTrack = newValue }
    }

    var nextTrack: Track? { playlist.nextTrack }
    var previousTrack: Track? { playlist.previousTrack }

    var hasCurrentTrack: Bool { playlist.hasCurrentTrack }
    var hasNextTrack: Bool { playlist.hasNextTrack }
    var hasPreviousTrack: Bool { playlist.hasPreviousTrack }

    var count: Int { playlist.count }
    var loadedTracksCount: Int { playlist.loadedTracksCount }
    var isEmpty: Bool { playlist.isEmpty }
    var isLoadedTracksEmpty: Bool { playlist.isLoadedTracksEmpty }
    @MainActor var isFiltering: Bool { !normalizedSearchText.isEmpty }
    @MainActor var filteredTracks: [Track] {
        let searchText = normalizedSearchText
        guard !searchText.isEmpty else { return tracks }

        return tracks.filter { track in
            searchableText(for: track).localizedCaseInsensitiveContains(searchText)
        }
    }
    @MainActor var isFilteredTracksEmpty: Bool { filteredTracks.isEmpty }

    var canMakeCanonical: Bool { playlist.canMakeCanonical }

    @MainActor private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @MainActor private func searchableText(for track: Track) -> String {
        [
            track.metadata.title.current,
            track.metadata.artist.current,
            track.metadata.albumTitle.current,
            track.metadata.albumArtist.current,
            track.url.deletingPathExtension().lastPathComponent,
            track.url.lastPathComponent
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }
}

extension PlaylistModel: Equatable {
    static func == (lhs: PlaylistModel, rhs: PlaylistModel) -> Bool {
        lhs.playlist == rhs.playlist
    }
}

extension PlaylistModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(playlist)
    }
}

extension PlaylistModel: Sequence {
    func makeIterator() -> Playlist.Iterator {
        playlist.makeIterator()
    }
}

extension PlaylistModel {
    var segments: Playlist.Segments {
        get { playlist.segments }
        set { playlist.segments = newValue }
    }

    var playbackMode: PlaybackMode {
        get { segments.state.playbackMode }
        set { segments.state.playbackMode = newValue }
    }

    var playbackLooping: Bool {
        get { segments.state.playbackLooping }
        set { segments.state.playbackLooping = newValue }
    }

    @MainActor func restorePlaybackState(_ state: Playlist.State) {
        segments.state = state
        currentTrack = state.currentTrackURL.flatMap(getTrack)
    }

    @MainActor func restoreCurrentTrackFromPlaybackState() {
        currentTrack = segments.state.currentTrackURL.flatMap(getTrack)
    }

    @MainActor func updateCurrentTrackElapsedTime(_ elapsedTime: TimeInterval) {
        guard hasCurrentTrack else { return }
        segments.state.currentTrackElapsedTime = Swift.max(.zero, elapsedTime)
    }
}

extension PlaylistModel {
    private func captureIndices() -> TrackIndexer.Value {
        OrderedDictionary(
            uniqueKeysWithValues: tracks
                .map(\.url)
                .compactMap { url in
                    guard let id = UUID(uuidString: url.deletingPathExtension().lastPathComponent) else { return nil }
                    return (id, url.pathExtension)
                }
        )
    }

    private func indexTracks(with value: TrackIndexer.Value) throws {
        guard mode.isCanonical else { return }
        playlist.indexer.value = value
        try playlist.indexer.write()
    }

    @MainActor private func persistTrackIndex(failureMessage: String) {
        do {
            try indexTracks(with: captureIndices())
            operationError = nil
        } catch {
            operationError = .trackIndexFailed(message: failureMessage)
        }
    }

    @MainActor func loadTracks() async {
        guard mode.isCanonical, !isLoading else { return }
        defer {
            isLoading = false
            loadingProgress = nil
        }

        loadingProgress = nil
        loadError = nil
        isLoading = true

        playlist.loadIndexer()
        playlist.tracks.removeAll()
        guard !playlist.indexer.value.isEmpty else { return }

        var loadedCount = 0
        for await (_, track) in playlist.indexer.loadTracks() {
            playlist.tracks.append(track)
            loadedCount += 1
            loadingProgress = CGFloat(loadedCount) / CGFloat(count)
        }

        restoreCurrentTrackFromPlaybackState()

        let failedCount = Swift.max(0, count - loadedCount)
        if failedCount > 0 {
            loadError = .missingTracks(count: failedCount)
        }
    }
}

extension PlaylistModel {
    @MainActor func bindTo(_ id: UUID, mode: Playlist.Mode = .referenced) {
        guard !playlist.mode.isCanonical else { return }
        if mode.isCanonical, let playlist = Playlist(loadingWith: id) {
            self.playlist = playlist
        } else {
            playlist = .referenced(bindingTo: id)
        }
    }

    @MainActor func makeCanonical() async throws {
        guard let canonicalPlaylist = try await Playlist(makingCanonical: playlist) else { return }
        playlist = canonicalPlaylist
        try indexTracks(with: captureIndices())
        library?.add([canonicalPlaylist])
    }

    func write(segments: [Playlist.Segment] = Playlist.Segment.allCases) throws {
        try playlist.write(segments: segments)
    }

    @MainActor func save(segments: [Playlist.Segment] = Playlist.Segment.allCases) {
        do {
            try write(segments: segments)
            operationError = nil
        } catch {
            operationError = .saveFailed(segments: segments)
        }
    }

    @MainActor func clearOperationError() {
        operationError = nil
    }

    @MainActor func clearLoadError() {
        loadError = nil
    }
}

extension PlaylistModel {
    func getTrack(at url: URL) -> Track? {
        playlist.getTrack(at: url)
    }

    func createTrack(from url: URL) async -> Track? {
        await playlist.createTrack(from: url)
    }

    func getOrCreateTrack(at url: URL) async -> Track? {
        await playlist.getOrCreateTrack(at: url)
    }
}

extension PlaylistModel {
    @MainActor func move(fromOffsets indices: IndexSet, toOffset destination: Int) {
        playlist.move(fromOffsets: indices, toOffset: destination)

        persistTrackIndex(failureMessage: "Could not update the playlist track order.")
    }

    @MainActor func play(_ url: URL) async -> Track? {
        guard let track = await getOrCreateTrack(at: url) else { return nil }
        playlist.add([track])
        currentTrack = track
        segments.state.currentTrackElapsedTime = .zero

        persistTrackIndex(failureMessage: "Could not update the playlist contents.")
        return track
    }

    @MainActor func add(_ urls: [URL], at destination: Int? = nil) async {
        var tracks: [Track] = []
        for url in urls {
            guard let track = await getOrCreateTrack(at: url) else { continue }
            tracks.append(track)
        }
        playlist.add(tracks, at: destination)

        persistTrackIndex(failureMessage: "Could not update the playlist contents.")
    }

    @MainActor func append(_ urls: [URL]) async {
        for url in urls {
            guard let track = await getOrCreateTrack(at: url) else { continue }
            playlist.add([track])
        }

        persistTrackIndex(failureMessage: "Could not update the playlist contents.")
    }

    @MainActor func remove(_ urls: [URL]) async {
        for url in urls {
            guard let track = await getOrCreateTrack(at: url) else { continue }
            playlist.remove([track])
            selectedTracks.remove(track)
        }

        persistTrackIndex(failureMessage: "Could not update the playlist contents.")
    }

    @MainActor func clear() async {
        await remove(playlist.map(\.url))
    }
}
