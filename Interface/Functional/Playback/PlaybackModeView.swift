//
//  PlaybackModeView.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/8.
//

import SFSafeSymbols
import SwiftUI

enum PlaybackRepeatMode: Equatable {
    case off
    case list
    case single

    var systemSymbol: SFSymbol {
        switch self {
        case .off, .list:
            .repeat
        case .single:
            .repeat1
        }
    }

    var isActive: Bool {
        self != .off
    }

    var name: String {
        switch self {
        case .off:
            String(localized: "Repeat Off")
        case .list:
            String(localized: "Repeat Playlist")
        case .single:
            String(localized: "Repeat Track")
        }
    }
}

extension PlaylistModel {
    func setPlaybackMode(_ mode: PlaybackMode) {
        playbackMode = mode
        playbackLooping = false
    }

    func cyclePlaybackMode(negate: Bool = false) {
        setPlaybackMode(playbackMode.cycle(negate: negate))
    }

    var playbackRepeatMode: PlaybackRepeatMode {
        if playbackLooping {
            return .single
        }

        return playbackMode == .loop ? .list : .off
    }

    func cyclePlaybackRepeatMode() {
        switch playbackRepeatMode {
        case .off:
            playbackMode = .loop
            playbackLooping = false
        case .list:
            playbackLooping = true
        case .single:
            playbackMode = .sequential
            playbackLooping = false
        }
    }
}

struct PlaybackRepeatView: View {
    var mode: PlaybackRepeatMode

    var body: some View {
        Image(systemSymbol: mode.systemSymbol)
            .aliveHighlight(mode.isActive)
            .help(mode.name)
    }
}

struct PlaybackModeView: View {
    var mode: PlaybackMode

    var body: some View {
        HStack {
            Image(systemSymbol: mode.systemSymbol)

            Text(Self.name(of: mode))
        }
        .tag(mode)
    }

    static func name(of mode: PlaybackMode) -> String {
        switch mode {
        case .sequential:
            String(localized: "Sequential")
        case .loop:
            String(localized: "Sequential Loop")
        case .shuffle:
            String(localized: "Shuffle")
        }
    }
}

#Preview {
    ForEach(PlaybackMode.allCases) { mode in
        PlaybackModeView(mode: mode)
    }
}
