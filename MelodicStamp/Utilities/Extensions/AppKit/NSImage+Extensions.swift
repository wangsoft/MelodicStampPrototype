//
//  NSImage+Extensions.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/24.
//

import AppKit
import CSFBAudioEngine
import MediaPlayer

extension NSImage {
    var attachedPicture: AttachedPicture? {
        tiffRepresentation.flatMap { .init(imageData: $0) }
    }

    func attachedPicture(of type: AttachedPicture.`Type`) -> AttachedPicture? {
        guard let tiffRepresentation else { return nil }
        return .init(imageData: tiffRepresentation, type: type)
    }
}

extension NSImage {
    var mediaItemArtwork: MPMediaItemArtwork {
        .init(boundsSize: size) { _ in
            self
        }
    }
}

extension NSImage {
    func squared() -> NSImage {
        let originalSize = size
        let maxLength = max(originalSize.width, originalSize.height)
        let newSize = NSSize(width: maxLength, height: maxLength)

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = .high

        let origin = NSPoint(
            x: (maxLength - originalSize.width) / 2,
            y: (maxLength - originalSize.height) / 2
        )
        draw(
            in: NSRect(origin: origin, size: originalSize),
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0
        )

        newImage.unlockFocus()
        return newImage
    }
}
