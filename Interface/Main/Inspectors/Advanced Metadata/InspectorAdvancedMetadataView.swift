//
//  InspectorAdvancedMetadataView.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/24.
//

import Luminare
import SwiftUI

struct InspectorAdvancedMetadataView: View {
    @Environment(MetadataEditorModel.self) private var metadataEditor

    @State private var ratingDecreasedAnimation: Bool = false
    @State private var ratingIncreasedAnimation: Bool = false

    var body: some View {
        if !metadataEditor.hasMetadata {
            ExcerptView(tab: SidebarInspectorTab.advancedMetadata)
        } else {
            AutoScrollView(.vertical) {
                VStack(spacing: 24) {
                    LabeledSection {
                        compilationEditor()

                        ratingEditor()
                    }

                    LabeledSection("Release Date") {
                        releaseDateEditor()
                    }

                    LabeledSection("Sorting") {
                        sortingEditor()
                    }

                    LabeledSection("Album Sorting") {
                        albumSortingEditor()
                    }

                    LabeledSection("Copyright") {
                        copyrightEditor()
                    }

                    LabeledSection("Music Brainz") {
                        musicBrainzEditor()
                    }

                    LabeledSection("Miscellaneous") {
                        commentEditor()
                    }
                }
                .padding(.horizontal)
            }
            .scrollClipDisabled()
        }
    }

    @ViewBuilder private func compilationEditor() -> some View {
        LabeledOptionalControl(
            entries: metadataEditor[extracting: \.isCompilation],
            defaultValue: false
        ) { binding in
            Toggle(isOn: binding) {
                EmptyView()
            }
            .toggleStyle(.switch)
        } emptyView: {
            EmptyView()
        } label: {
            Text("Compilation")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private func ratingEditor() -> some View {
        HStack {
            let binding: Binding<Int> = Binding {
                metadataEditor[extracting: \.rating].projectedUnwrappedValue()?
                    .wrappedValue ?? 0
            } set: { newValue in
                metadataEditor[extracting: \.rating].setAll(newValue)
            }
            let isModified = metadataEditor[extracting: \.rating].isModified

            LabeledTextField(
                "Rating", entries: metadataEditor[extracting: \.rating],
                format: .number
            )

            Button {
                binding.wrappedValue -= 1
                ratingDecreasedAnimation.toggle()
            } label: {
                Image(systemSymbol: .handThumbsdownFill)
                    .symbolEffect(.bounce, value: ratingDecreasedAnimation)
                    .foregroundStyle(.tint)
                    .tint(isModified ? .accent : .secondary)
            }

            Button {
                binding.wrappedValue += 1
                ratingIncreasedAnimation.toggle()
            } label: {
                Image(systemSymbol: .handThumbsupFill)
                    .symbolEffect(.bounce, value: ratingIncreasedAnimation)
                    .foregroundStyle(.tint)
                    .tint(isModified ? .accent : .secondary)
            }
        }
        .buttonStyle(.alive)
    }

    @ViewBuilder private func releaseDateEditor() -> some View {
        HStack {
            let isModified = metadataEditor[extracting: \.releaseDate].isModified

            LabeledTextField("Release Date", text: metadataEditor[extracting: \.releaseDate])

            Button {
                metadataEditor[extracting: \.releaseDate].setAll(Date.now.formatted(date: .complete, time: .shortened))
            } label: {
                Image(systemSymbol: .dotScope)
                    .foregroundStyle(.tint)
                    .tint(isModified ? .accent : .secondary)
            }
        }
        .buttonStyle(.alive)
    }

    @ViewBuilder private func sortingEditor() -> some View {
        LabeledTextField(
            "Title Sort Order",
            text: metadataEditor[extracting: \.titleSortOrder]
        ) {
            Text("Title")
        }

        LabeledTextField(
            "Artist Sort Order",
            text: metadataEditor[extracting: \.artistSortOrder]
        ) {
            Text("Artist")
        }

        LabeledTextField(
            "Composer Sort Order",
            text: metadataEditor[extracting: \.composerSortOrder]
        ) {
            Text("Composer")
        }

        LabeledTextField(
            "Genre Sort Order",
            text: metadataEditor[extracting: \.genreSortOrder]
        ) {
            Text("Genre")
        }
    }

    @ViewBuilder private func albumSortingEditor() -> some View {
        LabeledTextField(
            "Album Title Sort Order",
            text: metadataEditor[extracting: \.albumTitleSortOrder]
        ) {
            Text("Album Title")
        }

        LabeledTextField(
            "Album Artist Sort Order",
            text: metadataEditor[extracting: \.albumArtistSortOrder]
        ) {
            Text("Album Artist")
        }
    }

    @ViewBuilder private func copyrightEditor() -> some View {
        LabeledTextField(
            "ISRC", entries: metadataEditor[extracting: \.isrc], format: .isrc
        )

        LabeledTextField(
            "Catalog Number", text: metadataEditor[extracting: \.mcn]
        )
    }

    @ViewBuilder private func musicBrainzEditor() -> some View {
        LabeledTextField(
            "Recording ID",
            entries: metadataEditor[extracting: \.musicBrainzRecordingID],
            format: .uuid
        )

        LabeledTextField(
            "Release ID",
            entries: metadataEditor[extracting: \.musicBrainzReleaseID],
            format: .uuid
        )
    }

    @ViewBuilder private func commentEditor() -> some View {
        LabeledTextEditor(
            "Comment",
            entries: metadataEditor[extracting: \.comment]
        )
    }
}
