//
//  MainView.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2024/11/22.
//

import Defaults
import Luminare
import SwiftUI

struct MainView: View {
    @Environment(LibraryModel.self) private var library
    @Environment(WindowManagerModel.self) private var windowManager
    @Environment(FileManagerModel.self) private var fileManager
    @Environment(PlaylistModel.self) private var playlist
    @Environment(MetadataEditorModel.self) private var metadataEditor

    @Environment(\.appearsActive) private var appearsActive

    @State private var inspectorLyrics: LyricsModel = .init()
    @State private var displayLyrics: LyricsModel = .init()

    var body: some View {
        @Bindable var windowManager = windowManager

        content()
            .frame(minWidth: 600, minHeight: 400)
            .inspector(isPresented: $windowManager.isInspectorPresented) {
                inspector()
                    .ignoresSafeArea()
                    .inspectorColumnWidth(min: 300, ideal: 400, max: 700)
                    .animation(nil, value: playlist.selectedTracks) // Remove strange transitions when selection changes
            }
            .luminareMinHeight(38)
            .metadataSaveErrorAlert(for: metadataEditor)
            .metadataUpdateErrorAlert(for: metadataEditor)
    }

    @ViewBuilder private func content() -> some View {
        Group {
            switch windowManager.selectedContentTab {
            case .playlist:
                PlaylistView()
                    .toolbar {
                        FileToolbar()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaPadding(.bottom, 94)
                    .toolbarBackgroundVisibility(appearsActive ? .hidden : .automatic, for: .windowToolbar)
                    .morphed(isActive: appearsActive && !windowManager.isInFullScreen)
            case .leaflet:
                LeafletView()
                    .environment(displayLyrics)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .toolbar(removing: .title)
                    .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            }
        }
    }

    @ViewBuilder private func inspector() -> some View {
        Group {
            switch windowManager.selectedInspectorTab {
            case .commonMetadata:
                InspectorCommonMetadataView()
                    .toolbar {
                        if windowManager.isInspectorPresented {
                            EditorToolbar()
                        }
                    }
            case .advancedMetadata:
                InspectorAdvancedMetadataView()
                    .toolbar {
                        if windowManager.isInspectorPresented {
                            EditorToolbar()
                        }
                    }
            case .lyrics:
                InspectorLyricsView()
                    .toolbar {
                        if windowManager.isInspectorPresented {
                            EditorToolbar()
                        }
                    }
                    .toolbar {
                        if windowManager.isInspectorPresented {
                            LyricsToolbar()
                        }
                    }
            case .library:
                InspectorLibraryView()
                    .toolbar {
                        if windowManager.isInspectorPresented {
                            LibraryToolbar()
                        }
                    }
            case .analytics:
                InspectorAnalyticsView()
            }
        }
        .environment(inspectorLyrics)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaPadding(.bottom, 94)
        .morphed(isActive: appearsActive && !windowManager.isInFullScreen)
    }
}

#if DEBUG
    #Preview(traits: .modifier(PreviewEnvironmentsModifier())) {
        MainView()
    }
#endif
