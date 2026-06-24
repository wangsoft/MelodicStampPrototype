//
//  TTMLInspectorLyricLineView.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/22.
//

import Luminare
import SwiftUI

struct TTMLInspectorLyricLineView: View {
    @Environment(\.luminareAnimationFast) private var animationFast

    var isHighlighted: Bool = false
    var line: TTMLLyricLine

    @State private var isHovering: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(verbatim: "\(line.position)")
                    .foregroundStyle(.tint)

                Text(verbatim: "#\(line.index)")
            }
            .font(.caption)
            .monospaced()
            .foregroundColor(.secondary)

            TTMLInspectorLyricsView(isHighlighted: isHighlighted, lyrics: line.lyrics)

            if !line.backgroundLyrics.isEmpty {
                HStack {
                    Text("background")
                        .foregroundStyle(.tint)

                    VStack {
                        Divider()
                    }
                }
                .font(.caption)
                .monospaced()
                .foregroundStyle(.secondary)

                TTMLInspectorLyricsView(isHighlighted: isHighlighted, lyrics: line.backgroundLyrics)
            }
        }
        .padding(.vertical, 16)
        .onHover { hover in
            withAnimation(animationFast) {
                isHovering = hover
            }
        }
        .overlay(alignment: .trailing) {
            if isHovering {
                ZStack(alignment: .trailing) {
                    Rectangle()
                        .frame(width: 4)
                        .foregroundStyle(.tint)
                        .padding(.vertical, 6)

                    VStack {
                        DurationText(
                            duration: line.beginTime.flatMap(Duration.init),
                            pattern: .minuteSecond(
                                padMinuteToLength: 0,
                                fractionalSecondsLength: 3
                            )
                        )
                        .foregroundStyle(.background)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 4)
                        .background {
                            Rectangle()
                                .foregroundStyle(.tint)
                        }
                        .clipShape(.rect(cornerRadii: .init(
                            topLeading: 6, bottomLeading: 6, bottomTrailing: 0, topTrailing: 6
                        )))

                        Spacer()

                        DurationText(
                            duration: line.endTime.flatMap(Duration.init),
                            pattern: .minuteSecond(
                                padMinuteToLength: 0,
                                fractionalSecondsLength: 3
                            )
                        )
                        .foregroundStyle(.background)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 4)
                        .background {
                            Rectangle()
                                .foregroundStyle(.tint)
                        }
                        .clipShape(.rect(cornerRadii: .init(
                            topLeading: 6, bottomLeading: 6, bottomTrailing: 6, topTrailing: 0
                        )))
                    }
                }
                .font(.footnote)
                .monospaced()
                .allowsHitTesting(false)
            }
        }
    }
}

#Preview {
    TTMLInspectorLyricLineView(isHighlighted: false, line: .init(
        index: 0, position: .main,
        lyrics: .init(
            beginTime: 0, endTime: 1000,
            children: [
                .init(text: "A", trailingSpaceCount: 1),
                .init(text: "word", trailingSpaceCount: 1),
                .init(text: "based", trailingSpaceCount: 1),
                .init(text: "lyric", trailingSpaceCount: 1),
                .init(text: "line.")
            ],
            translations: [
                .init(locale: .init(identifier: "zh-CN"), text: "翻译")
            ],
            roman: "Roman"
        ),
        backgroundLyrics: .init(
            beginTime: 0, endTime: 1000,
            children: [
                .init(text: "A", trailingSpaceCount: 1),
                .init(text: "word", trailingSpaceCount: 1),
                .init(text: "based", trailingSpaceCount: 1),
                .init(text: "background", trailingSpaceCount: 1),
                .init(text: "lyric", trailingSpaceCount: 1),
                .init(text: "line.")
            ],
            translations: [
                .init(locale: .init(identifier: "zh-CN"), text: "翻译")
            ],
            roman: "Roman"
        )
    ))
}
