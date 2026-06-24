//
//  FileManagerModel.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/25.
//

import CSFBAudioEngine
import SwiftUI
import UniformTypeIdentifiers

enum FileOpenerPresentationStyle {
    case inCurrentPlaylist
    case replacingCurrentPlaylistOrSelection
    case formingNewPlaylist
}

enum FileAdderPresentationStyle {
    case toCurrentPlaylist
    case replacingCurrentPlaylistOrSelection
    case formingNewPlaylist
}

struct FileImportError: Identifiable, Equatable {
    let id = UUID()
    var message: String

    static func inaccessible(_ urls: [URL]) -> Self {
        let fileNames = urls.map(\.lastPathComponent).sorted()
        if fileNames.count == 1, let fileName = fileNames.first {
            return .init(message: "Could not access \(fileName).")
        }

        return .init(message: "Could not access \(fileNames.count) selected items.")
    }

    static var noSupportedFiles: Self {
        .init(message: "No supported audio files were found.")
    }

    static func == (lhs: FileImportError, rhs: FileImportError) -> Bool {
        lhs.message == rhs.message
    }
}

@Observable final class FileManagerModel {
    private weak var playlist: PlaylistModel?
    private weak var player: PlayerModel?

    var importError: FileImportError?

    var isFileOpenerPresented: Bool = false
    private var fileOpenerPresentationStyle: FileOpenerPresentationStyle = .inCurrentPlaylist

    var isFileAdderPresented: Bool = false
    private var fileAdderPresentationStyle: FileAdderPresentationStyle = .toCurrentPlaylist

    init(player: PlayerModel, playlist: PlaylistModel) {
        self.player = player
        self.playlist = playlist
    }

    func emitOpen(style: FileOpenerPresentationStyle = .inCurrentPlaylist) {
        isFileOpenerPresented = true
        fileOpenerPresentationStyle = style
    }

    func emitAdd(style: FileAdderPresentationStyle = .toCurrentPlaylist) {
        isFileAdderPresented = true
        fileAdderPresentationStyle = style
    }

    func open(url: URL, openWindow: OpenWindowAction) {
        guard let url = resolvedOpenURL(url) else { return }

        Task { @MainActor in
            switch fileOpenerPresentationStyle {
            case .inCurrentPlaylist:
                await player?.play(url)
            case .replacingCurrentPlaylistOrSelection:
                await playlist?.clear()
                await player?.play(url)
            case .formingNewPlaylist:
                openWindow(id: WindowID.content(), value: CreationParameters(
                    playlist: .referenced([url]), shouldPlay: true,
                    initialWindowStyle: .miniPlayer
                ))
            }
        }
    }

    func add(urls: [URL], openWindow: OpenWindowAction) {
        let urls = resolvedAddedURLs(urls)
        guard !urls.isEmpty else { return }

        Task { @MainActor in
            switch fileAdderPresentationStyle {
            case .toCurrentPlaylist:
                await playlist?.append(urls)
            case .replacingCurrentPlaylistOrSelection:
                await playlist?.clear()
                await playlist?.append(urls)
            case .formingNewPlaylist:
                openWindow(id: WindowID.content(), value: CreationParameters(
                    playlist: .referenced(urls)
                ))
            }
        }
    }
}

extension FileManagerModel {
    func resolvedOpenURL(_ url: URL) -> URL? {
        importError = nil

        guard url.isReachable else {
            importError = .inaccessible([url])
            return nil
        }

        guard FileHelper.filter(url: url) != nil else {
            importError = .noSupportedFiles
            return nil
        }

        return url
    }

    func resolvedAddedURLs(_ urls: [URL]) -> [URL] {
        importError = nil

        let inaccessibleURLs = urls.filter { !$0.isReachable }
        guard inaccessibleURLs.isEmpty else {
            importError = .inaccessible(inaccessibleURLs)
            return []
        }

        let resolvedURLs = urls
            .flatMap { FileHelper.flatten(contentsOf: $0) }
            .compactMap { FileHelper.filter(url: $0) }

        guard !resolvedURLs.isEmpty else {
            importError = .noSupportedFiles
            return []
        }

        return resolvedURLs
    }

    func clearImportError() {
        importError = nil
    }
}
