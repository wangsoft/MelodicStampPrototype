//
//  LyricsTextFileLoader.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

import Foundation

struct LyricsTextFileLoader {
    enum LoadError: LocalizedError, Equatable {
        case unavailable(URL)
        case unreadable(URL, String)

        var errorDescription: String? {
            switch self {
            case let .unavailable(url):
                String(localized: "Could not access \(url.lastPathComponent).")
            case let .unreadable(url, reason):
                String(localized: "Could not read \(url.lastPathComponent): \(reason)")
            }
        }
    }

    func load(from url: URL) throws -> String {
        do {
            guard let content = try url.withSecurityScopedAccess({
                try String(contentsOf: $0, encoding: .utf8)
            }) else {
                throw LoadError.unavailable(url)
            }

            return content
        } catch let error as LoadError {
            throw error
        } catch {
            throw LoadError.unreadable(url, error.localizedDescription)
        }
    }
}
