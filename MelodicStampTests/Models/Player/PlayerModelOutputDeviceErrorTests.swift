//
//  PlayerModelOutputDeviceErrorTests.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

@testable import MelodicStamp
import CAAudioHardware
import Foundation
import Testing

@MainActor @Suite struct PlayerModelOutputDeviceErrorTests {
    enum TestOutputDeviceError: LocalizedError {
        case unavailable

        var errorDescription: String? {
            "Audio device query failed"
        }
    }

    final class OutputDeviceFailurePlayer: BlankPlayer {
        override func availableOutputDevices() throws -> [AudioDevice] {
            throw TestOutputDeviceError.unavailable
        }
    }

    final class RecoveringOutputDevicePlayer: BlankPlayer {
        var failsDeviceRefresh = true

        override func availableOutputDevices() throws -> [AudioDevice] {
            if failsDeviceRefresh {
                throw TestOutputDeviceError.unavailable
            } else {
                return []
            }
        }

        override func defaultOutputDevice() throws -> AudioDevice? {
            nil
        }

        override func defaultSystemOutputDevice() throws -> AudioDevice? {
            nil
        }
    }

    @Test func recordsOutputDeviceErrorWhenDeviceRefreshFails() {
        let library = LibraryModel()
        let playlist = PlaylistModel(library: library)
        let player = PlayerModel(OutputDeviceFailurePlayer(), library: library, playlist: playlist)

        player.updateOutputDevices()

        #expect(player.outputDeviceError?.message == "Audio device query failed")

        player.clearOutputDeviceError()

        #expect(player.outputDeviceError == nil)
    }

    @Test func doesNotRepeatDismissedOutputDeviceRefreshErrorUntilRecovery() {
        let library = LibraryModel()
        let playlist = PlaylistModel(library: library)
        let outputDevicePlayer = RecoveringOutputDevicePlayer()
        let player = PlayerModel(outputDevicePlayer, library: library, playlist: playlist)

        player.updateOutputDevices()
        player.clearOutputDeviceError()

        player.updateOutputDevices()

        #expect(player.outputDeviceError == nil)

        outputDevicePlayer.failsDeviceRefresh = false
        player.updateOutputDevices()

        outputDevicePlayer.failsDeviceRefresh = true
        player.updateOutputDevices()

        #expect(player.outputDeviceError?.message == "Audio device query failed")
    }
}
