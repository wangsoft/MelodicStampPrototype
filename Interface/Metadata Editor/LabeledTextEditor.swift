//
//  LabeledTextEditor.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/18.
//

import Luminare
import SwiftUI
import UniformTypeIdentifiers

enum LabeledTextEditorLayout {
    case field
    case button
}

enum LabeledTextEditorStyle {
    case regular
    case code
}

struct LabeledTextEditor<Label, Actions, V>: View where Label: View, Actions: View, V: StringRepresentable & Hashable {
    typealias Entries = MetadataBatchEditingEntries<V?>

    @Environment(\.undoManager) private var undoManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.luminareAnimationFast) private var animationFast
    @Environment(\.luminareCompactButtonCornerRadii) private var cornerRadii

    private var entries: Entries
    private var layout: LabeledTextEditorLayout
    private var style: LabeledTextEditorStyle
    private var allowedFileTypes: [UTType]
    private var networkLoader: (() async throws -> String?)?
    @ViewBuilder private var label: () -> Label
    @ViewBuilder private var actions: () -> Actions

    @State private var textInput: TextInputModel<V> = .init()

    @State private var isPresented: Bool = false
    @State private var isFileImporterPresented: Bool = false
    @State private var isLoadingFromNetwork: Bool = false
    @State private var networkLoadingError: String?
    @State private var fileLoadingError: String?

    init(
        entries: Entries,
        layout: LabeledTextEditorLayout = .field,
        style: LabeledTextEditorStyle = .regular,
        allowedFileTypes: [UTType] = [.text, .ttml],
        networkLoader: (() async throws -> String?)? = nil,
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder actions: @escaping () -> Actions
    ) {
        self.entries = entries
        self.layout = layout
        self.style = style
        self.allowedFileTypes = allowedFileTypes
        self.networkLoader = networkLoader
        self.label = label
        self.actions = actions
    }

    init(
        entries: Entries,
        layout: LabeledTextEditorLayout = .field,
        style: LabeledTextEditorStyle = .regular,
        allowedFileTypes: [UTType] = [.text, .ttml],
        networkLoader: (() async throws -> String?)? = nil,
        @ViewBuilder label: @escaping () -> Label
    ) where Actions == EmptyView {
        self.init(
            entries: entries,
            layout: layout,
            style: style,
            allowedFileTypes: allowedFileTypes,
            networkLoader: networkLoader,
            label: label
        ) {
            EmptyView()
        }
    }

    init(
        _ key: LocalizedStringKey,
        entries: Entries,
        layout: LabeledTextEditorLayout = .field,
        style: LabeledTextEditorStyle = .regular,
        allowedFileTypes: [UTType] = [.text, .ttml],
        networkLoader: (() async throws -> String?)? = nil,
        @ViewBuilder actions: @escaping () -> Actions
    ) where Label == Text {
        self.init(
            entries: entries,
            layout: layout,
            style: style,
            allowedFileTypes: allowedFileTypes,
            networkLoader: networkLoader
        ) {
            Text(key)
        } actions: {
            actions()
        }
    }

    init(
        _ key: LocalizedStringKey,
        entries: Entries,
        layout: LabeledTextEditorLayout = .field,
        style: LabeledTextEditorStyle = .regular,
        allowedFileTypes: [UTType] = [.text, .ttml],
        networkLoader: (() async throws -> String?)? = nil
    ) where Label == Text, Actions == EmptyView {
        self.init(
            key,
            entries: entries,
            layout: layout,
            style: style,
            allowedFileTypes: allowedFileTypes,
            networkLoader: networkLoader
        ) {
            EmptyView()
        }
    }

    var body: some View {
        let isModified = entries.isModified
        let binding: Binding<String> = Binding {
            entries.projectedUnwrappedValue()?.wrappedValue.stringRepresentation ?? ""
        } set: { newValue in
            entries.setAll { V.wrappingUpdate($0, with: newValue) }
        }

        Group {
            switch layout {
            case .field:
                HStack {
                    HStack {
                        label()

                        Spacer()

                        if !isEmpty {
                            Text("\(binding.wrappedValue.count) words")
                                .foregroundStyle(.placeholder)
                        }
                    }
                    .modifier(LuminareHoverable())
                    .luminareAspectRatio(contentMode: .fill)
                    .overlay {
                        Group {
                            if entries.isModified {
                                UnevenRoundedRectangle(cornerRadii: cornerRadii)
                                    .stroke(.primary)
                                    .fill(.quinary.opacity(0.5))
                                    .foregroundStyle(.tint)
                            }
                        }
                        .allowsHitTesting(false)
                    }

                    Button {
                        isPresented.toggle()
                    } label: {
                        Image(systemSymbol: .textRedaction)
                            .foregroundStyle(.tint)
                            .tint(isModified ? .accent : .secondary)
                    }
                    .buttonStyle(.alive)
                }
            case .button:
                Button {
                    isPresented.toggle()
                } label: {
                    label()
                }
            }
        }
        .onAppear {
            textInput.updateCheckpoint(for: entries)
        }
        .onChange(of: isPresented, initial: true) { _, newValue in
            if newValue {
                textInput.updateCheckpoint(for: entries)
            } else {
                textInput.registerUndoFromCheckpoint(for: entries, in: undoManager)
            }
        }
        .onChange(of: entries.projectedValue?.wrappedValue) { oldValue, _ in
            guard !isPresented else { return }
            textInput.registerUndo(oldValue, for: entries, in: undoManager)
        }
        .sheet(isPresented: $isPresented) {
            // In order to make safe area work, we need a wrapper
            ScrollView {
                Group {
                    switch style {
                    case .regular:
                        regularEditor(binding: binding)
                    case .code:
                        codeEditor(binding: binding)
                    }
                }
                .scrollDisabled(true)
            }
            .scrollContentBackground(.hidden)
            .scrollClipDisabled()
            .presentationAttachmentBar(edge: .bottom, attachment: controls)
            .presentationSizing(.fitted)
            .frame(minWidth: 725, minHeight: 500, maxHeight: 1200)
            .alert(
                "Failed to Load Lyrics",
                isPresented: Binding {
                    networkLoadingError != nil
                } set: { isPresented in
                    if !isPresented {
                        networkLoadingError = nil
                    }
                }
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(networkLoadingError ?? "")
            }
            .alert(
                "Failed to Load File",
                isPresented: Binding {
                    fileLoadingError != nil
                } set: { isPresented in
                    if !isPresented {
                        fileLoadingError = nil
                    }
                }
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(fileLoadingError ?? "")
            }
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: allowedFileTypes
            ) { result in
                switch result {
                case let .success(url):
                    do {
                        let content = try LyricsTextFileLoader().load(from: url)
                        entries.setAll { V.wrappingUpdate($0, with: content) }
                    } catch {
                        fileLoadingError = error.localizedDescription
                    }
                case let .failure(error):
                    guard !error.isUserCancellation else { return }
                    fileLoadingError = error.localizedDescription
                }
            }
        }
    }

    private var isEmpty: Bool {
        if let binding = entries.projectedValue {
            textInput.isEmpty(value: binding.wrappedValue)
        } else {
            true
        }
    }

    @ViewBuilder private func regularEditor(binding: Binding<String>) -> some View {
        LuminareTextEditor(text: binding)
            .luminareBordered(false)
            .luminareHasBackground(false)
    }

    @ViewBuilder private func codeEditor(binding: Binding<String>) -> some View {
        LuminareTextEditor(text: binding)
            .luminareBordered(false)
            .luminareHasBackground(false)
            .monospaced()
    }

    @ViewBuilder private func controls() -> some View {
        Group {
            Button {
                entries.restoreAll()
            } label: {
                Image(systemSymbol: .arrowUturnLeft)
            }
            .foregroundStyle(.red)
            .disabled(!entries.isModified)

            Button {
                entries.setAll { V.wrappingUpdate($0, with: "") }
            } label: {
                Image(systemSymbol: .trash)
            }
            .foregroundStyle(.red)
            .disabled(isEmpty)

            if Actions.self != EmptyView.self {
                Divider()

                actions()
            }

            Spacer()

            if let networkLoader {
                Button {
                    loadFromNetwork(networkLoader)
                } label: {
                    HStack {
                        Text("Load from Network")

                        if isLoadingFromNetwork {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "network")
                        }
                    }
                }
                .disabled(isLoadingFromNetwork)
            }

            Button {
                isFileImporterPresented = true
            } label: {
                HStack {
                    Text("Load from File")

                    Image(systemSymbol: .docText)
                }
            }

            Divider()

            Button {
                isPresented = false
            } label: {
                Text("Done")
            }
            .foregroundStyle(.tint)
        }
        .buttonStyle(.alive)
    }

    @MainActor private func loadFromNetwork(_ loader: @escaping () async throws -> String?) {
        guard !isLoadingFromNetwork else { return }

        Task {
            isLoadingFromNetwork = true
            defer { isLoadingFromNetwork = false }

            do {
                guard let content = try await loader() else { return }
                entries.setAll { V.wrappingUpdate($0, with: content) }
            } catch {
                networkLoadingError = error.localizedDescription
            }
        }
    }
}

private extension Error {
    var isUserCancellation: Bool {
        let nsError = self as NSError
        return nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError
    }
}

#if DEBUG
    private struct LabeledTextEditorPreview: View {
        @Environment(MetadataEditorModel.self) private var metadataEditor

        var body: some View {
            LabeledTextEditor(entries: metadataEditor[extracting: \.lyrics]) {
                Text(verbatim: "Editor")
            } actions: {
                Image(systemSymbol: .info)
            }
        }
    }

    #Preview(traits: .modifier(PreviewEnvironmentsModifier())) {
        LabeledTextEditorPreview()
    }
#endif
