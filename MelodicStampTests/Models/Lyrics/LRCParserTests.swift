//
//  LRCParserTests.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

@testable import MelodicStamp
import Testing

@Suite struct LRCParserTests {
    @Test func parsesTranslationTaggedLineIntoPreviousLyric() throws {
        let parser = try LRCParser(string: """
        [00:01.00]Hello
        [00:01.00][tr:zh]你好
        [00:02.00]World
        """)

        #expect(parser.lines.count == 2)
        #expect(parser.lines[0].content == "Hello")
        #expect(parser.lines[0].translation == "你好")
        #expect(parser.lines[1].content == "World")
    }

    @Test func skipsUntaggedLinesWithoutDroppingLaterLyrics() throws {
        let parser = try LRCParser(string: """
        this line is not valid lrc
        [00:03.00]Still parsed
        """)

        #expect(parser.lines.count == 1)
        #expect(parser.lines[0].content == "Still parsed")
    }
}
