//
//  MakeCloseDelegated.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/26.
//

import SwiftUI

struct MakeCloseDelegated: NSViewRepresentable {
    var shouldClose: Bool = false
    var onClose: (NSWindow, Bool) -> ()

    func makeNSView(context: Context) -> CloseDelegatedWindowView {
        let view = CloseDelegatedWindowView(delegate: context.coordinator.delegate)
        context.coordinator.delegate.parent = self
        return view
    }

    func updateNSView(_ nsView: CloseDelegatedWindowView, context: Context) {
        context.coordinator.delegate.parent = self
        nsView.applyDelegateIfPossible()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator {
        let delegate: CloseDelegatedWindowDelegate

        init(parent: MakeCloseDelegated) {
            self.delegate = .init(parent: parent)
        }
    }
}

final class CloseDelegatedWindowView: NSView {
    let delegate: CloseDelegatedWindowDelegate

    init(delegate: CloseDelegatedWindowDelegate) {
        self.delegate = delegate
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

    func applyDelegateIfPossible() {
        guard let window else { return }
        if !(window.delegate is CloseDelegatedWindowDelegate) {
            delegate.originalDelegate = window.delegate
            window.delegate = delegate
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyDelegateIfPossible()
    }
}

class CloseDelegatedWindowDelegate: NSObject, NSWindowDelegate {
    weak var originalDelegate: NSWindowDelegate?
    var parent: MakeCloseDelegated

    init(parent: MakeCloseDelegated) {
        self.parent = parent
    }

    func windowShouldClose(_ window: NSWindow) -> Bool {
        parent.onClose(window, parent.shouldClose)
        return parent.shouldClose
    }

    override func responds(to aSelector: Selector!) -> Bool {
        super.responds(to: aSelector) || (originalDelegate?.responds(to: aSelector) ?? false)
    }

    override func forwardingTarget(for _: Selector!) -> Any? {
        originalDelegate
    }
}
