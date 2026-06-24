//
//  FileHelper.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/17.
//

import Foundation
import UniformTypeIdentifiers

enum FileHelper {}

extension FileHelper {
    static func flatten(contentsOf folderURL: URL, allowedContentTypes: Set<UTType> = allowedContentTypes, isRecursive: Bool = true) -> [URL] {
        guard folderURL.canAccessSecurityScopedResourceOrIsReachable() else { return [] }
        guard folderURL.hasDirectoryPath else { return [folderURL] }

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return contents.flatMap { url in
            if url.hasDirectoryPath, isRecursive {
                return flatten(contentsOf: url, allowedContentTypes: allowedContentTypes, isRecursive: isRecursive)
            }

            return if let url = filter(url: url) {
                [url]
            } else { [] }
        }
    }

    static func filter(url: URL) -> URL? {
        guard url.isFileURL else { return nil }

        let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey])
        guard let fileType = resourceValues?.contentType else { return nil }

        return allowedContentTypes.contains(fileType) ? url : nil
    }
}
