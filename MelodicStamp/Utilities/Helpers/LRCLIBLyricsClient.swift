//
//  LRCLIBLyricsClient.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/7.
//

import Foundation

struct LRCLIBLyricsClient {
    struct Request {
        var trackName: String
        var artistName: String?
        var albumName: String?
        var duration: TimeInterval?
    }

    private struct Response: Decodable {
        var syncedLyrics: String?
        var plainLyrics: String?
    }

    enum LyricsError: LocalizedError {
        case missingTrackName
        case invalidResponse
        case lyricsNotFound

        var errorDescription: String? {
            switch self {
            case .missingTrackName:
                String(localized: "Missing track title.")
            case .invalidResponse:
                String(localized: "The lyrics service returned an invalid response.")
            case .lyricsNotFound:
                String(localized: "No lyrics were found for this track.")
            }
        }
    }

    func fetchLyrics(for request: Request) async throws -> String {
        let trackName = normalized(request.trackName) ?? ""
        guard !trackName.isEmpty else { throw LyricsError.missingTrackName }

        var components = URLComponents(string: "https://lrclib.net/api/get")
        components?.queryItems = queryItems(for: request, trackName: trackName)

        guard let url = components?.url else { throw LyricsError.invalidResponse }

        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("MelodicStamp/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let response = response as? HTTPURLResponse else {
            throw LyricsError.invalidResponse
        }

        guard response.statusCode == 200 else {
            throw LyricsError.lyricsNotFound
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        if let syncedLyrics = normalized(decoded.syncedLyrics), !syncedLyrics.isEmpty {
            return syncedLyrics
        }

        if let plainLyrics = normalized(decoded.plainLyrics), !plainLyrics.isEmpty {
            return plainLyrics
        }

        throw LyricsError.lyricsNotFound
    }

    private func queryItems(for request: Request, trackName: String) -> [URLQueryItem] {
        var result: [URLQueryItem] = [
            .init(name: "track_name", value: trackName)
        ]

        if let artistName = normalized(request.artistName), !artistName.isEmpty {
            result.append(.init(name: "artist_name", value: artistName))
        }

        if let albumName = normalized(request.albumName), !albumName.isEmpty {
            result.append(.init(name: "album_name", value: albumName))
        }

        if let duration = request.duration, duration > 0 {
            result.append(.init(name: "duration", value: String(Int(duration.rounded()))))
        }

        return result
    }

    private func normalized(_ string: String?) -> String? {
        string?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
