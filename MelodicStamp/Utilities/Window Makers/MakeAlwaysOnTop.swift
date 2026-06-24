//
//  MakeAlwaysOnTop.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2025/1/2.
//

import SwiftUI

struct MakeAlwaysOnTop: NSViewRepresentable {
    @Binding var isAlwaysOnTop: Bool

    func makeNSView(context _: Context) -> AlwaysOnTopWindowView {
        let view = AlwaysOnTopWindowView()
        view.isAlwaysOnTop = isAlwaysOnTop
        return view
    }

    func updateNSView(_ nsView: AlwaysOnTopWindowView, context _: Context) {
        nsView.isAlwaysOnTop = isAlwaysOnTop
        nsView.applyWindowLevelIfPossible()
    }
}

final class AlwaysOnTopWindowView: NSView {
    var isAlwaysOnTop: Bool = true

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        isHidden = true
        translatesAutoresizingMaskIntoConstraints = false
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    override var intrinsicContentSize: NSSize {
        .zero
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyWindowLevelIfPossible() {
        guard let window else { return }

        let desiredLevel: NSWindow.Level = isAlwaysOnTop ? .floating : .normal
        if window.level != desiredLevel {
            window.level = desiredLevel
        }

        if isAlwaysOnTop {
            if !window.collectionBehavior.contains(.canJoinAllSpaces) {
                window.collectionBehavior.insert(.canJoinAllSpaces)
            }
        } else if window.collectionBehavior.contains(.canJoinAllSpaces) {
            window.collectionBehavior.remove(.canJoinAllSpaces)
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyWindowLevelIfPossible()
    }
}
