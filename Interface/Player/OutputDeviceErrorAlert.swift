//
//  OutputDeviceErrorAlert.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

import SwiftUI

extension View {
    func outputDeviceErrorAlert(for player: PlayerModel) -> some View {
        alert(
            "Output Device Error",
            isPresented: .init(
                get: {
                    player.outputDeviceError != nil
                },
                set: { isPresented in
                    if !isPresented {
                        player.clearOutputDeviceError()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                player.clearOutputDeviceError()
            }
        } message: {
            Text(player.outputDeviceError?.message ?? "")
        }
    }
}
