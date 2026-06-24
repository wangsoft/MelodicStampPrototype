//
//  LRCParser.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/1.
//

import Foundation
import RegexBuilder

@Observable final class LRCParser: LyricsParser {
    typealias Tag = LRCTag
    typealias Line = LRCLyricLine

    private(set) var lines: [LRCLyricLine] = []
    private(set) var attachments: LyricsAttachments = []
    private(set) var metadata: [LyricsMetadata] = []

    required init(string: String) throws {
        try parse(string: string)
    }

    private func parse(string: String) throws {
        let contents = string
            .split(separator: .newlineSequence)
            .map(String.init)

        for content in contents {
            if try Self.lineCommentRegex.wholeMatch(in: content) != nil {
                // Passes comment line
                continue
            }

            guard let match = try Self.lineRegex.wholeMatch(
                in: content.trimmingCharacters(in: .whitespacesAndNewlines)
            ) else { continue }
            // Output: (original, tagString, _, content)

            let tagString = String(match.output.1).trimmingCharacters(in: .whitespacesAndNewlines)
            let content = String(match.output.3).trimmingCharacters(in: .whitespacesAndNewlines)

            guard !tagString.isEmpty else { continue }
            var tags: [String] = []
            for match in tagString.matches(of: Self.tagRegex) {
                tags.append(String(match.output.1).trimmingCharacters(in: .whitespacesAndNewlines))
            }

            if content.isEmpty {
                // Metadata definition

                for tag in tags {
                    // Parses tag
                    do {
                        if let tag = try Self.parseTag(string: tag) {
                            switch tag {
                            case let .artist(value):
                                metadata.append(.artist(value))
                            case let .album(value):
                                metadata.append(.album(value))
                            case let .title(value):
                                metadata.append(.title(value))
                            case let .creator(value):
                                metadata.append(.lyricist(value))
                            case let .offset(value):
                                metadata.append(.offset(value))
                            default:
                                break
                            }
                        }
                    } catch {}
                }
            } else {
                // Lyric line

                var line: LRCLyricLine = .init(content: content)

                for tag in tags {
                    if let time = try? TimeInterval(timestamp: tag) {
                        if line.beginTime == nil {
                            line.beginTime = time
                        } else if line.endTime == nil {
                            line.endTime = time
                        }
                    }

                    if let parsedTag = try? Self.parseTag(string: tag) {
                        line.tags.append(parsedTag)
                    }
                }

                let isTranslation = line.tags.map(\.key).contains(.translation)
                if isTranslation {
                    // Appends translation to last line

                    let lastIndex = lines.endIndex - 1
                    guard lines.indices.contains(lastIndex) else { continue }

                    lines[lastIndex].translation = line.content
                } else {
                    lines.append(line)
                    attachments.formUnion(line.attachments)
                }
            }
        }
    }

    static func parseTag(string: String) throws -> Tag? {
        let regex = Regex {
            Capture {
                Tag.regex
            }
            ":"
            Capture {
                OneOrMore {
                    CharacterClass(.anyNonNewline)
                }
            }
        }

        guard let match = try regex.wholeMatch(in: string) else { return nil }
        let keyString = String(match.output.1)
        let valueString = String(match.output.2)

        guard let key = Tag.Key(rawValue: keyString) else { return nil }
        return try .init(key: key, rawValue: valueString)
    }
}

extension LRCParser {
    private static let tagRegex = Regex {
        "["
        Capture {
            OneOrMore(.anyNonNewline, .reluctant)
        }
        "]"
    }

    private static let lineRegex = Regex {
        Capture {
            ZeroOrMore {
                tagRegex
            }
        }
        Capture {
            ZeroOrMore(.anyNonNewline)
        }
    }

    private static let lineCommentRegex = Regex {
        "#"
        Capture {
            ZeroOrMore(.anyNonNewline)
        }
    }
}

extension LRCParser: Equatable {
    static func == (lhs: LRCParser, rhs: LRCParser) -> Bool {
        lhs.lines == rhs.lines
    }
}

extension LRCParser: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(lines)
    }
}
