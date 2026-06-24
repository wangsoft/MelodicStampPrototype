//
//  PlayerCommands.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/8.
//

import CAAudioHardware
import SwiftUI

struct PlayerCommands: Commands {
    @FocusedValue(PlaylistModel.self) private var playlist
    @FocusedValue(PlayerModel.self) private var player
    @FocusedValue(KeyboardControlModel.self) private var keyboardControl

    var body: some Commands {
        CommandMenu("Player") {
            Group {
                // MARK: Play / Pause

                Button(player?.isPlaying ?? false ? "Pause" : "Play") {
                    player?.togglePlayPause()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!isPlayable)

                Group {
                    // MARK: Fast Forward

                    Button("Fast Forward") {
                        keyboardControl?.handleProgressAdjustment(
                            phase: .all, sign: .plus
                        )
                    }
                    .keyboardShortcut(.rightArrow, modifiers: .command)
                    .modifierKeyAlternate(.shift) {
                        Button("Fast Forward") {
                            keyboardControl?.handleProgressAdjustment(
                                phase: .all, modifiers: .shift, sign: .plus
                            )
                        }
                        .badge("×5")
                    }
                    .modifierKeyAlternate(.option) {
                        Button("Fast Forward") {
                            keyboardControl?.handleProgressAdjustment(
                                phase: .all, modifiers: .option, sign: .plus
                            )
                        }
                        .badge("×0.1")
                    }

                    // MARK: Rewind

                    Button("Rewind") {
                        keyboardControl?.handleProgressAdjustment(
                            phase: .all, sign: .minus
                        )
                    }
                    .keyboardShortcut(.leftArrow, modifiers: .command)
                    .modifierKeyAlternate(.shift) {
                        Button("Rewind") {
                            keyboardControl?.handleProgressAdjustment(
                                phase: .all, modifiers: .shift, sign: .minus
                            )
                        }
                        .badge("×5")
                    }
                    .modifierKeyAlternate(.option) {
                        Button("Rewind") {
                            keyboardControl?.handleProgressAdjustment(
                                phase: .all, modifiers: .option, sign: .minus
                            )
                        }
                        .badge("×0.1")
                    }
                }
                .disabled(!isPlayable)

                Divider()

                Group {
                    // MARK: Mute

                    Group {
                        if let player {
                            @Bindable var player = player

                            Toggle("Mute", isOn: $player.isMuted)
                        } else {
                            Button("Mute") {
                                // Do nothing
                            }
                        }
                    }
                    .keyboardShortcut("m", modifiers: [.command, .control])

                    // MARK: Louder

                    Button("Louder") {
                        keyboardControl?.handleVolumeAdjustment(
                            phase: .all, sign: .plus
                        )
                    }
                    .keyboardShortcut(.upArrow, modifiers: .command)
                    .modifierKeyAlternate(.shift) {
                        Button("Louder") {
                            keyboardControl?.handleVolumeAdjustment(
                                phase: .all, modifiers: .shift, sign: .plus
                            )
                        }
                        .badge("×5")
                    }
                    .modifierKeyAlternate(.option) {
                        Button("Louder") {
                            keyboardControl?.handleVolumeAdjustment(
                                phase: .all, modifiers: .option, sign: .plus
                            )
                        }
                        .badge("×0.1")
                    }

                    // MARK: Quieter

                    Button("Quieter") {
                        keyboardControl?.handleVolumeAdjustment(
                            phase: .all, sign: .minus
                        )
                    }
                    .keyboardShortcut(.downArrow, modifiers: .command)
                    .modifierKeyAlternate(.shift) {
                        Button("Quieter") {
                            keyboardControl?.handleVolumeAdjustment(
                                phase: .all, modifiers: .shift, sign: .minus
                            )
                        }
                        .badge("×5")
                    }
                    .modifierKeyAlternate(.option) {
                        Button("Quieter") {
                            keyboardControl?.handleVolumeAdjustment(
                                phase: .all, modifiers: .option, sign: .minus
                            )
                        }
                        .badge("×0.1")
                    }
                }
                .disabled(!isPlayable)

                Divider()

                Group {
                    // MARK: Next Track

                    Button("Next Track") {
                        player?.playNextTrack()
                    }
                    .keyboardShortcut(.rightArrow, modifiers: [.command, .control])
                    .disabled(!hasNextTrack)

                    // MARK: Previous Track

                    Button("Previous Track") {
                        player?.playPreviousTrack()
                    }
                    .keyboardShortcut(.leftArrow, modifiers: [.command, .control])
                    .disabled(!hasPreviousTrack)
                }
                .disabled(!hasCurrentTrack)
            }
            .disabled(!hasPlayer || !hasPlayerKeyboardControl)

            // MARK: Playback

            if let playlist {
                @Bindable var playlist = playlist
                let playbackName = PlaybackModeView.name(of: playlist.playbackMode)

                Menu("Playback") {
                    ForEach(PlaybackMode.allCases) { mode in
                        let binding: Binding<Bool> = Binding {
                            playlist.playbackMode == mode
                        } set: { newValue in
                            guard newValue else { return }
                            playlist.setPlaybackMode(mode)
                        }

                        Toggle(isOn: binding) {
                            PlaybackModeView(mode: mode)
                        }
                    }

                    Divider()

                    Button {
                        playlist.cyclePlaybackRepeatMode()
                    } label: {
                        PlaybackRepeatView(mode: playlist.playbackRepeatMode)
                        Text(playlist.playbackRepeatMode.name)
                    }
                }
                .badge(playbackName)
            } else {
                Button("Playback") {}
            }

            // MARK: Output Device

            if let player {
                @Bindable var player = player
                let outputDeviceName = OutputDeviceView.name(of: player.selectedOutputDevice)

                Picker("Output Device", selection: $player.selectedOutputDevice) {
                    OutputDeviceList(devices: player.outputDevices, defaultSystemDevice: player.defaultSystemOutputDevice)
                }
                .badge(outputDeviceName)
            } else {
                Button("Output Device") {}
            }
        }
    }

    private var hasPlayer: Bool { player != nil }

    private var hasPlayerKeyboardControl: Bool { keyboardControl != nil }

    private var isPlayable: Bool { player?.isCurrentTrackPlayable ?? false }

    private var hasCurrentTrack: Bool { playlist?.hasCurrentTrack ?? false }

    private var hasPreviousTrack: Bool { playlist?.hasPreviousTrack ?? false }

    private var hasNextTrack: Bool { playlist?.hasNextTrack ?? false }
}
