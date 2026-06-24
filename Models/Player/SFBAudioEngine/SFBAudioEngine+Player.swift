//
//  SFBAudioEngine+Player.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/31.
//

import CAAudioHardware
import Foundation
import SFBAudioEngine

extension SFBAudioEnginePlayer: TypeNameReflectable {}

class SFBAudioEnginePlayer: NSObject, Player {
    init(_ player: AudioPlayer = .init()) {
        self.player = player
        super.init()

        self.player.delegate = self
    }

    var delegate: (any PlayerDelegate)?

    private var player: AudioPlayer
    private var mutedVolume: CGFloat?
    private var playbackAccesses: [SecurityScopedAccessToken] = []

    var isPlaying: Bool { isRunning && player.isPlaying }
    var isRunning: Bool { player.engineIsRunning }
    private(set) var isMuted: Bool = false

    var playbackTime: PlaybackTime? {
        player.time.flatMap {
            guard let total = $0.total, let current = $0.current else { return nil }
            return .init(duration: Duration(total), elapsed: current)
        }
    }

    var playbackVolume: CGFloat {
        if isMuted {
            if let mutedVolume {
                max(0, min(1, mutedVolume))
            } else {
                CGFloat(player.volume)
            }
        } else {
            max(0, min(1, CGFloat(player.volume)))
        }
    }

    func play(_ track: Track) {
        do {
            releasePlaybackAccesses()
            if let (decoder, accessToken) = try Self.decoder(for: track) {
                retainPlaybackAccess(accessToken)
                try player.play(decoder)
            }
        } catch {
            releasePlaybackAccesses()
            logger.error("\(error)")
            delegate?.player(self, encounteredError: error)
        }
    }

    func enqueue(_ track: Track) {
        do {
            if let (decoder, accessToken) = try Self.decoder(for: track) {
                retainPlaybackAccess(accessToken)
                try player.enqueue(decoder)
            }
        } catch {
            logger.error("\(error)")
            delegate?.player(self, encounteredError: error)
        }
    }

    func play() {
        do {
            try player.play()
        } catch {
            logger.error("\(error)")
            delegate?.player(self, encounteredError: error)
        }
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.stop()
        releasePlaybackAccesses()
    }

    func mute() {
        mutedVolume = playbackVolume
        seekVolume(to: .zero)

        // It's crucial to update `isMuted` at the very last
        isMuted = true
    }

    func unmute() {
        // It's crucial to update `isMuted` at the very beginning
        isMuted = false

        guard let mutedVolume else { return }
        seekVolume(to: mutedVolume)
    }

    func seekTime(to time: TimeInterval) {
        player.seek(time: time)
    }

    func seekProgress(to progress: CGFloat) {
        let progress = max(0, min(1, progress))
        player.seek(position: Double(progress))
    }

    func seekVolume(to volume: CGFloat) {
        let volume = max(0, min(1, volume))
        do {
            if isMuted {
                mutedVolume = volume
            } else {
                try player.setVolume(Float(volume))
            }
        } catch {
            logger.error("\(error)")
        }
    }

    func withEngine(_ block: @escaping (AVAudioEngine) -> ()) {
        player.withEngine { engine in
            block(engine)
        }
    }

    func availableOutputDevices() throws -> [AudioDevice] {
        try AudioDevice.devices
            .filter { try $0.supportsOutput }
            .filter { try $0.isAlive }
            .filter { try !$0.isHidden }
            .filter {
                // Filter out inappropriate types
                let inappropriateTypes: [AudioDevice.TransportType] = [
                    .aggregate
                ]
                return try !inappropriateTypes.contains($0.transportType)
            }
    }

    func defaultOutputDevice() throws -> AudioDevice? {
        try .defaultOutputDevice
    }

    func defaultSystemOutputDevice() throws -> AudioDevice? {
        try .defaultSystemOutputDevice
    }

    func selectedOutputDevice() throws -> AudioDevice? {
        let devices = try availableOutputDevices()
        let deviceID = player.outputDeviceID

        if let device = devices.first(where: { $0.objectID == deviceID }) {
            return device
        } else {
            return devices.first
        }
    }

    func selectOutputDevice(_ device: AudioDevice) throws {
        try player.setOutputDeviceID(device.objectID)
    }
}

extension SFBAudioEnginePlayer {
    private func retainPlaybackAccess(_ accessToken: SecurityScopedAccessToken?) {
        guard let accessToken else { return }
        playbackAccesses.append(accessToken)
    }

    private func releasePlaybackAccesses() {
        playbackAccesses.removeAll()
    }

    static func decoder(for track: Track, enablesDoP: Bool = false) throws -> (PCMDecoding, SecurityScopedAccessToken?)? {
        let url = track.url
        guard let accessToken = SecurityScopedAccessToken(url: url) else {
            guard url.isReachable else { return nil }
            return try decoder(for: url, enablesDoP: enablesDoP).map { ($0, nil) }
        }

        do {
            guard let decoder = try decoder(for: url, enablesDoP: enablesDoP) else { return nil }
            return (decoder, accessToken)
        } catch {
            accessToken.stopAccessing()
            throw error
        }
    }

    private static func decoder(for url: URL, enablesDoP: Bool) throws -> PCMDecoding? {
        let pathExtension = url.pathExtension.lowercased()
        if AudioDecoder.handlesPaths(withExtension: pathExtension) {
            return try AudioDecoder(url: url)
        } else if DSDDecoder.handlesPaths(withExtension: pathExtension) {
            let dsdDecoder = try DSDDecoder(url: url)
            return enablesDoP ? try DoPDecoder(decoder: dsdDecoder) : try DSDPCMDecoder(decoder: dsdDecoder)
        } else {
            return nil
        }
    }
}

extension SFBAudioEnginePlayer: AudioPlayer.Delegate {
    func audioPlayerEndOfAudio(_ audioPlayer: AudioPlayer) {
        releasePlaybackAccesses()
        delegate?.playerDidFinishPlaying(self)

        if let delegate = delegate as? AudioPlayer.Delegate {
            delegate.audioPlayerEndOfAudio?(audioPlayer)
        }
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, decodingStarted decoder: any PCMDecoding) {
        if let delegate = delegate as? AudioPlayer.Delegate {
            delegate.audioPlayer?(audioPlayer, decodingStarted: decoder)
        }
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, decodingComplete decoder: any PCMDecoding) {
        if let delegate = delegate as? AudioPlayer.Delegate {
            delegate.audioPlayer?(audioPlayer, decodingComplete: decoder)
        }
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, encounteredError error: any Error) {
        releasePlaybackAccesses()
        if let delegate = delegate as? AudioPlayer.Delegate {
            delegate.audioPlayer?(audioPlayer, encounteredError: error)
        }
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, renderingStarted decoder: any PCMDecoding) {
        if let delegate = delegate as? AudioPlayer.Delegate {
            delegate.audioPlayer?(audioPlayer, renderingStarted: decoder)
        }
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, renderingComplete decoder: any PCMDecoding) {
        if let delegate = delegate as? AudioPlayer.Delegate {
            delegate.audioPlayer?(audioPlayer, renderingComplete: decoder)
        }
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, renderingWillStart decoder: any PCMDecoding, at hostTime: UInt64) {
        if let delegate = delegate as? AudioPlayer.Delegate {
            delegate.audioPlayer?(audioPlayer, renderingWillStart: decoder, at: hostTime)
        }
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, renderingWillComplete decoder: any PCMDecoding, at hostTime: UInt64) {
        if let delegate = delegate as? AudioPlayer.Delegate {
            delegate.audioPlayer?(audioPlayer, renderingWillComplete: decoder, at: hostTime)
        }
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, decoderCanceled decoder: any PCMDecoding, framesRendered: AVAudioFramePosition) {
        releasePlaybackAccesses()
        if let delegate = delegate as? AudioPlayer.Delegate {
            delegate.audioPlayer?(audioPlayer, decoderCanceled: decoder, framesRendered: framesRendered)
        }
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, nowPlayingChanged nowPlaying: (any PCMDecoding)?) {
        if let delegate = delegate as? AudioPlayer.Delegate {
            delegate.audioPlayer?(audioPlayer, nowPlayingChanged: nowPlaying)
        }
    }

    func audioPlayer(_ audioPlayer: AudioPlayer, playbackStateChanged playbackState: AudioPlayer.PlaybackState) {
        if let delegate = delegate as? AudioPlayer.Delegate {
            delegate.audioPlayer?(audioPlayer, playbackStateChanged: playbackState)
        }
    }

    func audioPlayerAVAudioEngineConfigurationChange(_ audioPlayer: AudioPlayer) {
        if let delegate = delegate as? AudioPlayer.Delegate {
            delegate.audioPlayerAVAudioEngineConfigurationChange?(audioPlayer)
        }
    }
}
