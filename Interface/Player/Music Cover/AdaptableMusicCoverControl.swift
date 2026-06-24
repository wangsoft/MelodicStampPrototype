//
//  AdaptableMusicCoverControl.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/1.
//

import CSFBAudioEngine
import SwiftUI

struct AdaptableMusicCoverControl: View {
    typealias Entries = MetadataBatchEditingEntries<Set<AttachedPicture>>

    @Environment(AttachedPicturesHandlerModel.self) private var attachedPicturesHandler

    @Environment(\.undoManager) private var undoManager

    @Namespace private var localNamespace

    var entries: Entries
    var type: AttachedPicture.`Type`
    var maxResolution: CGFloat? = 128

    @State private var isImagePickerPresented: Bool = false
    @State private var isHeaderHovering: Bool = false

    var body: some View {
        Button {
            isImagePickerPresented = true
        } label: {
            imageView()
                .motionCard()
                .padding(.horizontal, 16)
        }
        .buttonStyle(.alive)
        .shadow(color: .black.opacity(0.1), radius: 5)
        .padding(.top, 8)
        .overlay(alignment: .top, content: header)
        .contextMenu {
            contextMenu()
        }
        .fileImporter(
            isPresented: $isImagePickerPresented,
            allowedContentTypes: AttachedPicturesHandlerModel
                .allowedContentTypes
        ) { result in
            switch result {
            case let .success(url):
                guard
                    let image = url.compactSecurityScopedAccess({ NSImage(contentsOf: $0) }),
                    let attachedPicture = image.attachedPicture(of: type)
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

    private var isModified: Bool {
        attachedPicturesHandler.isModified(
            of: [type], entries: entries
        )
    }

    @ViewBuilder private func header() -> some View {
        Group {
            if isHeaderHovering {
                HStack(spacing: 2) {
                    Button {
                        attachedPicturesHandler.restore(
                            of: [type], entries: entries,
                            undoManager: undoManager
                        )
                    } label: {
                        Image(systemSymbol: .arrowUturnLeft)
                    }
                    .disabled(
                        !attachedPicturesHandler.isModified(
                            of: [type],
                            entries: entries
                        )
                    )

                    Button {
                        attachedPicturesHandler.remove(
                            of: [type], entries: entries,
                            undoManager: undoManager
                        )
                    } label: {
                        Image(systemSymbol: .trash)
                    }
                }
                .buttonStyle(.alive)
                .foregroundStyle(.red)
                .bold()
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background {
                    Rectangle()
                        .fill(.ultraThickMaterial)
                        .clipShape(.capsule)
                        .matchedGeometryEffect(
                            id: "headerBackground", in: localNamespace
                        )
                }
            } else {
                AttachedPictureTypeView(type: type)
                    .fixedSize()
                    .font(.caption)
                    .foregroundStyle(.placeholder)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 6)
                    .background {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .clipShape(.capsule)
                            .matchedGeometryEffect(
                                id: "headerBackground", in: localNamespace
                            )
                    }
            }
        }
        .animation(.smooth(duration: 0.25), value: isHeaderHovering)
        .onHover { hover in
            isHeaderHovering = hover
        }
    }

    @ViewBuilder private func imageView() -> some View {
        Group {
            if
                let binding = entries.projectedValue,
                let image = [AttachedPicture](binding.wrappedValue)
                .first(where: { $0.type == type })
                .flatMap(\.image) {
                MusicCover(images: [image], cornerRadius: 8)
            } else {
                MusicCover(cornerRadius: 8)
            }
        }
        .overlay {
            if isModified {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.clear)
                    .stroke(.tint, lineWidth: 4)
            }
        }
        .clipShape(.rect(cornerRadius: 8))
    }

    @ViewBuilder private func contextMenu() -> some View {
        Button("Restore") {
            attachedPicturesHandler.restore(
                of: [type], entries: entries,
                undoManager: undoManager
            )
        }
        .disabled(
            !attachedPicturesHandler.isModified(
                of: [type],
                entries: entries
            )
        )

        Button("Remove") {
            attachedPicturesHandler.remove(
                of: [type], entries: entries,
                undoManager: undoManager
            )
        }
    }

    private func registerUndo(_ oldValue: Set<AttachedPicture>, for entries: Entries) {
        guard oldValue != entries.projectedValue?.wrappedValue ?? [] else { return }
        undoManager?.registerUndo(withTarget: attachedPicturesHandler) { _ in
            Task { @MainActor in
                let entries = self.entries
                let fallback = attachedPicturesHandler.copy(contents: entries)
                entries.setAll(oldValue)

                registerUndo(fallback, for: entries)
            }
        }
    }
}

#if DEBUG
    private struct AdaptableMusicCoverControlPreview: View {
        @Environment(MetadataEditorModel.self) private var metadataEditor

        var body: some View {
            AdaptableMusicCoverControl(
                entries: metadataEditor[extracting: \.attachedPictures],
                type: .other
            )
        }
    }

    #Preview(traits: .modifier(PreviewEnvironmentsModifier())) {
        @Previewable @State var attachedPicturesHandler: AttachedPicturesHandlerModel = .init()

        AdaptableMusicCoverControlPreview()
            .environment(attachedPicturesHandler)
    }
#endif
