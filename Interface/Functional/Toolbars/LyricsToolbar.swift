//
//  LyricsToolbar.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/3.
//

import Luminare
import SwiftUI

struct LyricsToolbar: ToolbarContent {
    @Environment(MetadataEditorModel.self) private var metadataEditor

    var body: some ToolbarContent {
        ToolbarItem {
            LabeledTextEditor(
                entries: metadataEditor[extracting: \.lyrics],
                layout: .button, style: .code,
                networkLoader: loadLyricsFromNetwork
            ) {
                Label("Edit Lyrics", systemSymbol: .pencilLine)
            } actions: {
                Image(systemSymbol: .info)
                    .luminarePopover {
                        Text(LocalizedStringResource(
                            "Toolbar (Lyrics): (Popover) Information",
                            defaultValue: """
                            You can use [AMLL TTML Tool](https://steve-xmh.github.io/amll-ttml-tool) to create TTML lyrics through a refined interface.
                            """
                        ))
                        .padding()
                    }
            }
            .disabled(!metadataEditor.hasMetadata)
        }
    }

    private func loadLyricsFromNetwork() async throws -> String? {
        guard let request = lyricsRequest() else { return nil }
        return try await LRCLIBLyricsClient().fetchLyrics(for: request)
    }

    @MainActor private func lyricsRequest() -> LRCLIBLyricsClient.Request? {
        guard let metadata = metadataEditor.metadataSet.first else { return nil }

        return .init(
            trackName: metadata.title.current ?? metadata.url.deletingPathExtension().lastPathComponent,
            artistName: metadata.artist.current,
            albumName: metadata.albumTitle.current,
            duration: metadata.properties.duration
        )
    }
}
