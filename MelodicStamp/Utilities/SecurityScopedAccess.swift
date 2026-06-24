//
//  SecurityScopedAccess.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

import Foundation

enum SecurityScopedAccessError: Error {
    case unavailable(URL)
}

struct SecurityScopedAccess {
    var startAccessing: () -> Bool
    var stopAccessing: () -> Void
    var isReachable: () -> Bool

    init(
        startAccessing: @escaping () -> Bool,
        stopAccessing: @escaping () -> Void,
        isReachable: @escaping () -> Bool
    ) {
        self.startAccessing = startAccessing
        self.stopAccessing = stopAccessing
        self.isReachable = isReachable
    }

    init(url: URL) {
        self.init(
            startAccessing: {
                url.startAccessingSecurityScopedResource()
            },
            stopAccessing: {
                url.stopAccessingSecurityScopedResource()
            },
            isReachable: {
                url.isReachable
            }
        )
    }

    func perform<T>(_ operation: () throws -> T) rethrows -> T? {
        let didStartAccess = startAccessing()
        guard didStartAccess || isReachable() else { return nil }
        defer {
            if didStartAccess {
                stopAccessing()
            }
        }

        return try operation()
    }

    func perform<T>(_ operation: () async throws -> T) async rethrows -> T? {
        let didStartAccess = startAccessing()
        guard didStartAccess || isReachable() else { return nil }
        defer {
            if didStartAccess {
                stopAccessing()
            }
        }

        return try await operation()
    }
}

final class SecurityScopedAccessToken {
    private let stopAccessingHandler: () -> Void
    private var isAccessing: Bool = true

    init?(url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return nil }
        stopAccessingHandler = {
            url.stopAccessingSecurityScopedResource()
        }
    }

    deinit {
        stopAccessing()
    }

    func stopAccessing() {
        guard isAccessing else { return }
        isAccessing = false
        stopAccessingHandler()
    }
}

extension URL {
    func withSecurityScopedAccess<T>(_ operation: (URL) throws -> T) rethrows -> T? {
        try SecurityScopedAccess(url: self).perform {
            try operation(self)
        }
    }

    func withSecurityScopedAccess<T>(_ operation: (URL) async throws -> T) async rethrows -> T? {
        try await SecurityScopedAccess(url: self).perform {
            try await operation(self)
        }
    }

    func compactSecurityScopedAccess<T>(_ operation: (URL) throws -> T?) rethrows -> T? {
        try withSecurityScopedAccess(operation) ?? nil
    }

    func compactSecurityScopedAccess<T>(_ operation: (URL) async throws -> T?) async rethrows -> T? {
        try await withSecurityScopedAccess(operation) ?? nil
    }

    func securityScopedBookmarkData() throws -> Data {
        guard let data = try withSecurityScopedAccess({
            try $0.bookmarkData(options: [.withSecurityScope])
        }) else {
            throw SecurityScopedAccessError.unavailable(self)
        }

        return data
    }

    static func resolvingSecurityScopedBookmarkData(_ data: Data, bookmarkDataIsStale: inout Bool) throws -> URL {
        try URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            bookmarkDataIsStale: &bookmarkDataIsStale
        )
    }
}
