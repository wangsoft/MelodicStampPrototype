//
//  DelegatedPlaylistStorage.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/12.
//

import Defaults
import SwiftUI

extension DelegatedPlaylistStorage: TypeNameReflectable {}

extension DelegatedPlaylistStorage {
    struct PlaylistRestoreResult: Equatable {
        var urls: [URL]
        var failedBookmarkCount: Int
    }

    enum PlaylistRestoreError: Identifiable, Equatable {
        case decodeFailed
        case bookmarkResolutionFailed(count: Int)

        var id: String {
            switch self {
            case .decodeFailed:
                return "decodeFailed"
            case let .bookmarkResolutionFailed(count):
                return "bookmarkResolutionFailed-\(count)"
            }
        }

        var message: String {
            switch self {
            case .decodeFailed:
                return "Could not restore the previous playlist."
            case let .bookmarkResolutionFailed(count):
                if count == 1 {
                    return "Could not restore 1 playlist item from the previous session."
                }
                return "Could not restore \(count) playlist items from the previous session."
            }
        }
    }

    enum DelegatedPlaylist: Equatable, Hashable, Codable {
        case referenced(
            bookmarks: [Data],
            currentTrackURL: URL?,
            currentTrackElapsedTime: TimeInterval,
            playbackMode: PlaybackMode,
            playbackLooping: Bool
        )
        case canonical(UUID)
    }
}

struct DelegatedPlaylistStorage: View {
    @Environment(PlaylistModel.self) private var playlist
    @Environment(PlayerModel.self) private var player

    // MARK: Storages

    @SceneStorage(SceneStorageID.playlistData()) private var playlistData: Data?

    @SceneStorage(SceneStorageID.playbackVolume()) private var playbackVolume: Double?
    @SceneStorage(SceneStorageID.playbackMuted()) private var playbackMuted: Bool?

    // MARK: States

    @State private var playlistState: DelegatedStorageState<Data?> = .init()
    @State private var restoreError: PlaylistRestoreError?

    @State private var playbackVolumeState: DelegatedStorageState<Double?> = .init()
    @State private var playbackMutedState: DelegatedStorageState<Bool?> = .init()

    var body: some View {
        ZStack {
            playlistObservations()
            playbackVolumeObservations()
        }
        .onAppear {
            playlistState.isReady = true
        }
        .alert(
            "Playlist Restore Failed",
            isPresented: .init(
                get: {
                    restoreError != nil
                },
                set: { isPresented in
                    if !isPresented {
                        restoreError = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                restoreError = nil
            }
        } message: {
            Text(restoreError?.message ?? "")
        }
    }

    // MARK: Playlist

    @ViewBuilder private func playlistObservations() -> some View {
        Color.clear
            .onChange(of: playlistData) { _, newValue in
                playlistState.value = newValue
            }
            .onChange(of: playlist.hashValue) { _, _ in
                playlistState.isReady = false

                Task.detached {
                    try await storePlaylist()
                }
            }
            .onChange(of: playlistState.preparedValue) { _, newValue in
                guard let newValue else { return }

                if let data = newValue {
                    Task.detached {
                        let restoreError = await restorePlaylist(from: data)

                        Task { @MainActor in
                            self.restoreError = restoreError
                            logger.log("Successfully restored playlist")

                            // Dependents
                            playbackVolumeState.isReady = true
                            playbackMutedState.isReady = true
                        }
                    }
                }

                playlistState.isReady = false
            }
    }

    // MARK: Playback Volume

    @ViewBuilder private func playbackVolumeObservations() -> some View {
        Color.clear
            .onChange(of: playbackVolume) { _, newValue in
                playbackVolumeState.value = newValue
            }
            .onChange(of: player.volume) { _, newValue in
                playbackVolumeState.isReady = false
                playbackVolume = newValue
            }
            .onChange(of: playbackVolumeState.preparedValue) { _, newValue in
                guard let newValue else { return }

                if let volume = newValue {
                    player.volume = volume

                    logger.log("Successfully restored playback volume to \(volume)")
                }

                playbackVolumeState.isReady = false
            }

            .onChange(of: playbackMuted) { _, newValue in
                playbackMutedState.value = newValue
            }
            .onChange(of: player.isMuted) { _, newValue in
                playbackMutedState.isReady = false
                playbackMuted = newValue
            }
            .onChange(of: playbackMutedState.preparedValue) { _, newValue in
                guard let newValue else { return }

                if let isMuted = newValue {
                    player.isMuted = isMuted

                    logger.log("Successfully restored playback muted state to \(isMuted)")
                }

                playbackMutedState.isReady = false
            }
    }

    @MainActor
    private func restorePlaylist(from data: Data) async -> PlaylistRestoreError? {
        guard let delegatedPlaylist = try? JSONDecoder().decode(DelegatedPlaylist.self, from: data) else {
            return .decodeFailed
        }
        switch delegatedPlaylist {
        case let .referenced(bookmarks, currentTrackURL, currentTrackElapsedTime, playbackMode, playbackLooping):
            guard !playlist.mode.isCanonical else { break }

            let restoreResult = Self.restoreReferencedBookmarks(from: bookmarks)
            let urls = restoreResult.urls
            await playlist.append(urls)

            playlist.restorePlaybackState(.init(
                currentTrackURL: currentTrackURL,
                currentTrackElapsedTime: currentTrackElapsedTime,
                playbackMode: playbackMode,
                playbackLooping: playbackLooping
            ))
            if restoreResult.failedBookmarkCount > 0 {
                return .bookmarkResolutionFailed(count: restoreResult.failedBookmarkCount)
            }
        case let .canonical(id):
            switch playlist.mode {
            case .canonical:
                // Already handled by `ContentView`
                break
            case .referenced:
                playlist.bindTo(id, mode: .canonical)
                await playlist.loadTracks()
            }
        }

        return nil
    }

    private func storePlaylist() async throws {
        let delegatedPlaylist: DelegatedPlaylist
        switch playlist.mode {
        case .canonical:
            delegatedPlaylist = .canonical(playlist.id)
        case .referenced:
            let bookmarks: [Data] = try playlist.map(\.url).compactMap { url in
                try url.securityScopedBookmarkData()
            }

            delegatedPlaylist = .referenced(
                bookmarks: bookmarks,
                currentTrackURL: playlist.segments.state.currentTrackURL,
                currentTrackElapsedTime: playlist.segments.state.currentTrackElapsedTime,
                playbackMode: playlist.segments.state.playbackMode,
                playbackLooping: playlist.segments.state.playbackLooping
            )
        }
        playlistData = try? JSONEncoder().encode(delegatedPlaylist)
    }

    static func restoreReferencedBookmarks(from bookmarks: [Data]) -> PlaylistRestoreResult {
        var urls: [URL] = []
        var failedBookmarkCount = 0

        for bookmark in bookmarks {
            do {
                var isStale = false
                let url = try URL.resolvingSecurityScopedBookmarkData(bookmark, bookmarkDataIsStale: &isStale)
                guard !isStale else {
                    failedBookmarkCount += 1
                    continue
                }
                urls.append(url)
            } catch {
                failedBookmarkCount += 1
            }
        }

        return .init(urls: urls, failedBookmarkCount: failedBookmarkCount)
    }
}
