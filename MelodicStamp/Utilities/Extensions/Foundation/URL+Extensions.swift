//
//  URL+Extensions.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/25.
//

import Foundation

extension URL {
    var isFileExist: Bool {
        guard isFileURL else { return false }
        return FileManager.default.fileExists(atPath: path)
    }

    var isFileReadOnly: Bool {
        guard isFileURL else { return false }
        return FileManager.default.isWritableFile(atPath: path) == false
    }
}

extension URL {
    var isReachable: Bool {
        (try? checkResourceIsReachable()) ?? false
    }

    func canAccessSecurityScopedResourceOrIsReachable() -> Bool {
        SecurityScopedAccess(url: self).startAccessing() || isReachable
    }

    subscript(attribute key: FileAttributeKey) -> Any? {
        get {
            try? FileManager.default.attributesOfItem(atPath: standardizedFileURL.path(percentEncoded: false))[key]
        }

        set {
            guard let newValue else { return }
            try? FileManager.default.setAttributes([key: newValue], ofItemAtPath: standardizedFileURL.path(percentEncoded: false))
        }
    }
}
