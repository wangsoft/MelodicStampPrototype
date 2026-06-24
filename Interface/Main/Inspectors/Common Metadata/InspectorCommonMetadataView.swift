//
//  InspectorCommonMetadataView.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/24.
//

import CSFBAudioEngine
import Luminare
import SwiftUI

struct InspectorCommonMetadataView: View {
    @Environment(MetadataEditorModel.self) private var metadataEditor

    @Environment(\.undoManager) private var undoManager
    @Environment(\.luminareMinHeight) private var minHeight

    @State private var attachedPicturesHandler: AttachedPicturesHandlerModel =
        .init()

    @State private var isCoverPickerPresented: Bool = false
    @State private var chosenAttachedPictureType: AttachedPicture.`Type` =
        .frontCover

    @State private var isBPMStepperPresented: Bool = false

    var body: some View {
        if !metadataEditor.hasMetadata {
            ExcerptView(tab: SidebarInspectorTab.commonMetadata)
        } else {
            AutoScrollView(.vertical) {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        attachedPicturesEditor()
                            .padding(.vertical, 8)

                        AdaptableMusicCovers(
                            entries: metadataEditor[
                                extracting: \.attachedPictures
                            ]
                        ) {
                            Spacer()
                                .frame(height: 8)

                            Divider()
                                .padding(.horizontal, 16)
                        }
                        .environment(attachedPicturesHandler)
                        .padding(.horizontal, -16)
                        .contentMargins(
                            .horizontal, 16, for: .scrollIndicators
                        )
                    }

                    LabeledSection {
                        generalEditor()
                    }

                    LabeledSection("Album") {
                        albumEditor()
                    }

                    LabeledSection("Track & Disc") {
                        trackAndDiscEditor()
                    }
                }
                .padding(.horizontal)
            }
            .scrollClipDisabled()
        }
    }

    @ViewBuilder private func attachedPicturesEditor() -> some View {
        HStack(alignment: .center, spacing: 0) {
            Text("Pictures")
                .foregroundStyle(.secondary)

            Spacer()

            LuminareSection(hasPadding: false) {
                HStack(spacing: 2) {
                    let entries = metadataEditor[extracting: \.attachedPictures]
                    let types = attachedPicturesHandler.types(of: entries)
                    let availableTypes = Set(AttachedPicture.allTypes)
                        .subtracting(types)

                    Button(role: .destructive) {
                        attachedPicturesHandler.remove(
                            entries: entries, undoManager: undoManager
                        )
                    } label: {
                        HStack {
                            Image(systemSymbol: .trashFill)

                            Text("Clear")
                        }
                        .padding()
                    }
                    .buttonStyle(.luminareProminent)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: true, vertical: false)
                    .disabled(types.isEmpty)

                    Menu {
                        ForEach(AttachedPictureCategory.allCases) { category in
                            let availableTypesInCategory =
                                availableTypes.intersection(category.allTypes)

                            Section {
                                ForEach(
                                    Array(availableTypesInCategory).sorted(
                                        by: <), id: \.self
                                ) { type in
                                    Button {
                                        chosenAttachedPictureType = type
                                        isCoverPickerPresented = true
                                    } label: {
                                        AttachedPictureTypeView(type: type)
                                    }
                                }
                            } header: {
                                AttachedPictureCategoryView(category: category)
                            }
                        }
                    } label: {
                        Image(systemSymbol: .plus)
                    }
                    .aspectRatio(6 / 5, contentMode: .fit)
                    .disabled(availableTypes.isEmpty)
                    .fileImporter(
                        isPresented: $isCoverPickerPresented,
                        allowedContentTypes: AttachedPicturesHandlerModel
                            .allowedContentTypes
                    ) { result in
                        switch result {
                        case let .success(url):
                            guard
                                let image = url.compactSecurityScopedAccess({ NSImage(contentsOf: $0) }),
                                let attachedPicture = image.attachedPicture(
                                    of: chosenAttachedPictureType
                                )
                            else { break }

                            attachedPicturesHandler.replace(
                                [attachedPicture], entries: entries,
                                undoManager: undoManager
                            )
                        case .failure:
                            break
                        }
                    }
                }
                .buttonStyle(.luminare)
                .frame(height: minHeight)
            }
            .luminareBordered(false)
            .luminareButtonMaterial(.thin)
            .luminareSectionMasked(true)
            .luminareSectionMaxWidth(nil)
            .shadow(color: .black.opacity(0.1), radius: 15)
        }
    }

    @ViewBuilder private func generalEditor() -> some View {
        LabeledTextField("Title", text: metadataEditor[extracting: \.title])

        LabeledTextField("Artist", text: metadataEditor[extracting: \.artist])

        LabeledTextField(
            "Composer", text: metadataEditor[extracting: \.composer]
        )

        LabeledTextField("Genre", text: metadataEditor[extracting: \.genre])
    }

    @ViewBuilder private func albumEditor() -> some View {
        LabeledTextField(
            "Album Title", text: metadataEditor[extracting: \.albumTitle]
        )

        LabeledTextField(
            "Album Artist", text: metadataEditor[extracting: \.albumArtist]
        )
    }

    @ViewBuilder private func trackAndDiscEditor() -> some View {
        HStack {
            let isModified = metadataEditor[extracting: \.bpm].isModified

            LabeledTextField(
                "BPM", entries: metadataEditor[extracting: \.bpm],
                format: .number
            )

            if let binding = metadataEditor[extracting: \.bpm].projectedValue {
                Button {
                    isBPMStepperPresented.toggle()
                } label: {
                    Image(systemSymbol: .sliderHorizontal3)
                        .foregroundStyle(.tint)
                        .tint(isModified ? .accent : .secondary)
                }
                .popover(isPresented: $isBPMStepperPresented, arrowEdge: .top) {
                    LuminareStepper(
                        value: .init {
                            CGFloat(binding.wrappedValue ?? .zero)
                        } set: { _ in
                            // do nothing
                        },
                        source: .infinite(),
                        indicatorSpacing: 16,
                        onRoundedValueChange: { _, newValue in
                            binding.wrappedValue = Int(newValue)
                        }
                    )
                    .frame(width: 125, height: 30)
                }
            }
        }
        .buttonStyle(.alive)

        HStack {
            LabeledTextField(
                "No.", entries: metadataEditor[extracting: \.trackNumber],
                format: .number, showsLabel: false
            )
            .frame(maxWidth: 72)

            Image(systemSymbol: .poweron)
                .imageScale(.large)
                .rotationEffect(.degrees(21))
                .frame(width: 4)
                .foregroundStyle(.placeholder)

            LabeledTextField(
                "Tracks", entries: metadataEditor[extracting: \.trackCount],
                format: .number
            )
        }

        HStack {
            LabeledTextField(
                "No.", entries: metadataEditor[extracting: \.discNumber],
                format: .number, showsLabel: false
            )
            .frame(maxWidth: 72)

            Image(systemSymbol: .poweron)
                .imageScale(.large)
                .rotationEffect(.degrees(21))
                .frame(width: 4)
                .foregroundStyle(.placeholder)

            LabeledTextField(
                "Discs", entries: metadataEditor[extracting: \.discCount],
                format: .number
            )
        }
    }
}
