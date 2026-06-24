//
//  MetadataEditorProtocol.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/26.
//

import Foundation

struct MetadataEditingState: OptionSet {
    let rawValue: Int

    static let fine = MetadataEditingState(rawValue: 1 << 0)
    static let saving = MetadataEditingState(rawValue: 1 << 1)

    var isFine: Bool {
        switch self {
        case .fine:
            true
        default:
            false
        }
    }

    var isSaving: Bool {
        switch self {
        case .saving:
            true
        default:
            false
        }
    }
}

struct MetadataSaveError: Identifiable, Equatable {
    let id = UUID()
    var failedCount: Int
    var fileNames: [String]

    init(failedURLs: [URL]) {
        self.failedCount = failedURLs.count
        self.fileNames = failedURLs
            .map(\.lastPathComponent)
            .sorted()
    }

    static func == (lhs: MetadataSaveError, rhs: MetadataSaveError) -> Bool {
        lhs.failedCount == rhs.failedCount && lhs.fileNames == rhs.fileNames
    }
}

struct MetadataUpdateError: Identifiable, Equatable {
    let id = UUID()
    var failedCount: Int
    var fileNames: [String]

    init(failedURLs: [URL]) {
        self.failedCount = failedURLs.count
        self.fileNames = failedURLs
            .map(\.lastPathComponent)
            .sorted()
    }

    static func == (lhs: MetadataUpdateError, rhs: MetadataUpdateError) -> Bool {
        lhs.failedCount == rhs.failedCount && lhs.fileNames == rhs.fileNames
    }
}

@MainActor protocol MetadataEditorProtocol: AnyObject, Modifiable {
    var metadataSet: Set<Metadata> { get }
    var hasMetadata: Bool { get }
    var state: MetadataEditingState { get }
    var saveError: MetadataSaveError? { get set }
    var updateError: MetadataUpdateError? { get set }
}

extension MetadataEditorProtocol {
    var hasMetadata: Bool { !metadataSet.isEmpty }

    var state: MetadataEditingState {
        guard hasMetadata else { return [] }

        var result: MetadataEditingState = []
        let states = metadataSet.map(\.state)

        for state in states {
            switch state {
            case .fine:
                result.formUnion(.fine)
            case .saving:
                result.formUnion(.saving)
            default:
                break
            }
        }

        return result
    }

    @MainActor func restoreAll() {
        metadataSet.forEach { $0.restore() }
    }

    func updateAll(completion: (() -> ())? = nil) {
        let metadatas = metadataSet
        updateError = nil

        Task {
            let failedURLs = await withTaskGroup(of: URL?.self) { group in
                for metadata in metadatas {
                    group.addTask {
                        do {
                            try await metadata.update()
                            return nil
                        } catch {
                            return metadata.url
                        }
                    }
                }

                var failedURLs: [URL] = []
                for await failedURL in group {
                    if let failedURL {
                        failedURLs.append(failedURL)
                    }
                }
                return failedURLs
            }

            await MainActor.run {
                if !failedURLs.isEmpty {
                    updateError = .init(failedURLs: failedURLs)
                }
                completion?()
            }
        }
    }

    func writeAll(completion: (() -> ())? = nil) {
        let metadatas = metadataSet
        saveError = nil

        Task {
            let failedURLs = await withTaskGroup(of: URL?.self) { group in
                for metadata in metadatas {
                    group.addTask {
                        do {
                            try await metadata.write()
                            return nil
                        } catch {
                            return metadata.url
                        }
                    }
                }

                var failedURLs: [URL] = []
                for await failedURL in group {
                    if let failedURL {
                        failedURLs.append(failedURL)
                    }
                }
                return failedURLs
            }

            await MainActor.run {
                if !failedURLs.isEmpty {
                    saveError = .init(failedURLs: failedURLs)
                }
                completion?()
            }
        }
    }
}

extension MetadataEditorProtocol {
    var isModified: Bool {
        metadataSet.contains(where: \.isModified)
    }

    func clearSaveError() {
        saveError = nil
    }

    func clearUpdateError() {
        updateError = nil
    }
}
