//
//  MakeCustomizable.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/5.
//

import SwiftUI

struct MakeCustomizable: NSViewRepresentable {
    var customization: ((NSWindow) -> ())?
    var willAppear: ((NSWindow) -> ())?
    var didAppear: ((NSWindow) -> ())?
    var willDisappear: ((NSWindow) -> ())?
    var didDisappear: ((NSWindow) -> ())?

    func makeNSView(context _: Context) -> CustomizableWindowView {
        CustomizableWindowView(
            customization: customization,
            willAppear: willAppear,
            didAppear: didAppear,
            willDisappear: willDisappear,
            didDisappear: didDisappear
        )
    }

    func updateNSView(_ nsView: CustomizableWindowView, context _: Context) {
        nsView.customization = customization
        nsView.willAppear = willAppear
        nsView.didAppear = didAppear
        nsView.willDisappear = willDisappear
        nsView.didDisappear = didDisappear
        nsView.applyCustomizationIfPossible()
    }
}

final class CustomizableWindowView: NSView {
    var customization: ((NSWindow) -> ())?
    var willAppear: ((NSWindow) -> ())?
    var didAppear: ((NSWindow) -> ())?
    var willDisappear: ((NSWindow) -> ())?
    var didDisappear: ((NSWindow) -> ())?
    private weak var observedWindow: NSWindow?

    init(
        customization: ((NSWindow) -> ())? = nil,
        willAppear: ((NSWindow) -> ())? = nil, didAppear: ((NSWindow) -> ())? = nil,
        willDisappear: ((NSWindow) -> ())? = nil, didDisappear: ((NSWindow) -> ())? = nil
    ) {
        self.customization = customization
        self.willAppear = willAppear
        self.didAppear = didAppear
        self.willDisappear = willDisappear
        self.didDisappear = didDisappear
        super.init(frame: .zero)

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

    func applyCustomizationIfPossible() {
        guard let window else { return }
        customization?(window)
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if let window, window !== newWindow {
            willDisappear?(window)
        }
        if let newWindow, observedWindow !== newWindow {
            willAppear?(newWindow)
        }

        super.viewWillMove(toWindow: newWindow)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        guard let window else {
            if let observedWindow {
                didDisappear?(observedWindow)
            }
            observedWindow = nil
            return
        }

        let didMoveToNewWindow = observedWindow !== window
        observedWindow = window
        applyCustomizationIfPossible()

        if didMoveToNewWindow {
            didAppear?(window)
        }
    }
}
