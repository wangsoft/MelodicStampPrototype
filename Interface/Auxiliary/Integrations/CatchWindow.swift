//
//  CatchWindow.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/12.
//

import SwiftUI

struct CatchWindow<Content>: View where Content: View {
    @ViewBuilder var content: (NSWindow?) -> Content

    @State private var window: NSWindow?

    private func updateWindow(_ window: NSWindow) {
        if self.window !== window {
            self.window = window
        }
    }

    var body: some View {
        content(window)
            .background(MakeCustomizable(customization: { window in
                updateWindow(window)
            }, willAppear: { window in
                updateWindow(window)
            }, didAppear: { window in
                updateWindow(window)
            }))
    }
}
