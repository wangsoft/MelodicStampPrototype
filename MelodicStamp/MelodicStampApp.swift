//
//  MelodicStampApp.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2024/11/19.
//

import CSFBAudioEngine
import SwiftUI
import UniformTypeIdentifiers

@main
struct MelodicStampApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    // Globally managed models, uniqueness ensured
    @State private var floatingWindows: FloatingWindowsModel = .init()
    @State private var library: LibraryModel = .init()

    @State private var isAboutWindowPresented: Bool = false

    var body: some Scene {
        WindowGroup(id: WindowID.content(), for: CreationParameters.self) { $parameters in
            ContentView(parameters, appDelegate: appDelegate, library: library)
                .environment(\.appDelegate, appDelegate)
                .environment(floatingWindows)
                .environment(library)
                .onAppear {
                    appDelegate.resumeWindowSuspension()
                }
        } defaultValue: {
            CreationParameters()
        }
        .defaultSize(width: 960, height: 550)
        .windowToolbarStyle(.unified)
        .windowManagerRole(.principal)
        .restorationBehavior(.disabled)
        .handlesExternalEvents(matching: []) // Crucial for handling custom external events in `AppDelegate`
        .commands {
            LocalizedInspectorCommands()

            CommandGroup(replacing: .appInfo) {
                Button("About \(Bundle.main[localized: .displayName])") {
                    if isAboutWindowPresented {
                        dismissWindow(id: WindowID.about())
                    } else {
                        openWindow(id: WindowID.about())
                    }
                }
            }

            FileCommands()

            EditingCommands()

            PlayerCommands()

            PlaylistCommands(library: library)

            WindowCommands()
        }

        Window("About \(Bundle.main[localized: .displayName])", id: WindowID.about()) {
            AboutView()
                .onAppear {
                    isAboutWindowPresented = true
                }
                .onDisappear {
                    isAboutWindowPresented = false
                }
                .windowMinimizeBehavior(.disabled)
                .windowFullScreenBehavior(.disabled)
                .safeAreaPadding(.top, 0)
        }
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
        .defaultSize(width: 480, height: 360)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .windowManagerRole(.associated)
        .handlesExternalEvents(matching: []) // Crucial for handling custom external events in `AppDelegate`

        Settings {
            SettingsView()
                .windowMinimizeBehavior(.disabled)
                .windowFullScreenBehavior(.disabled)
        }
        .windowToolbarStyle(.unified)
        .windowManagerRole(.associated)
        .handlesExternalEvents(matching: []) // Crucial for handling custom external events in `AppDelegate`
    }
}

// TODO: Improve this
let allowedContentTypes: Set<UTType> = {
    var types: Set<UTType> = []
    types.formUnion(AudioDecoder.supportedMIMETypes.compactMap { UTType(mimeType: $0) })
    types.formUnion(DSDDecoder.supportedMIMETypes.compactMap { UTType(mimeType: $0) })
    types.formUnion([.ogg])
    return types
}()
