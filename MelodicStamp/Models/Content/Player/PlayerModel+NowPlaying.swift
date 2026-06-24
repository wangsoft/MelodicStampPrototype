//
//  PlayerModel+NowPlaying.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/22.
//

import Foundation
import MediaPlayer

extension PlayerModel {
    func updateNowPlayingState(with playbackState: PlaybackState) {
        let infoCenter = MPNowPlayingInfoCenter.default()

        infoCenter.playbackState = .init(playbackState)
    }

    func updateNowPlayingInfo(with playbackState: PlaybackState) {
        let infoCenter = MPNowPlayingInfoCenter.default()
        var info = infoCenter.nowPlayingInfo ?? .init()

        switch playbackState {
        case .playing, .paused:
            info[MPMediaItemPropertyPlaybackDuration] = TimeInterval(unwrappedPlaybackTime.duration)
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = unwrappedPlaybackTime.elapsed
        case .stopped:
            info[MPMediaItemPropertyPlaybackDuration] = nil
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = nil
        }

        infoCenter.nowPlayingInfo = info
    }

    func updateNowPlayingMetadataInfo(from track: Track?) {
        Task { @MainActor in
            if let track {
                track.metadata.updateNowPlayingInfo()
            } else {
                Metadata.resetNowPlayingInfo()
            }
        }
    }

    func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self else { return .noActionableNowPlayingItem }
            guard isCurrentTrackPlayable else { return .noActionableNowPlayingItem }

            if isPlaying {
                return .commandFailed
            } else {
                play()
                return .success
            }
        }

        // Pause
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .noActionableNowPlayingItem }
            guard isCurrentTrackPlayable else { return .noActionableNowPlayingItem }

            if !isPlaying {
                return .commandFailed
            } else {
                pause()
                return .success
            }
        }

        // Toggle play pause
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .noActionableNowPlayingItem }
            guard isCurrentTrackPlayable else { return .noActionableNowPlayingItem }

            togglePlayPause()
            return .success
        }

        // Skip forward
        commandCenter.skipForwardCommand.preferredIntervals = [1.0, 5.0, 15.0]
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            guard let self else { return .noActionableNowPlayingItem }
            guard isCurrentTrackPlayable else { return .noActionableNowPlayingItem }
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }

            adjustTime(delta: event.interval, sign: .plus)
            return .success
        }

        // Skip backward
        commandCenter.skipBackwardCommand.preferredIntervals = [1.0, 5.0, 15.0]
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            guard let self else { return .noActionableNowPlayingItem }
            guard isCurrentTrackPlayable else { return .noActionableNowPlayingItem }
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }

            adjustTime(delta: event.interval, sign: .minus)
            return .success
        }

        // Seek
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self else { return .noActionableNowPlayingItem }
            guard isCurrentTrackPlayable else { return .noActionableNowPlayingItem }
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }

            progress = event.positionTime / TimeInterval(unwrappedPlaybackTime.duration)
            return .success
        }

        // Next track
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .noSuchContent }
            guard hasNextTrack else { return .noSuchContent }

            playNextTrack()
            return .success
        }

        // Previous track
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .noSuchContent }
            guard hasPreviousTrack else { return .noSuchContent }

            playPreviousTrack()
            return .success
        }
    }
}
