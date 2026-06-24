# MelodicStampPrototype Onboarding Guide

## What Is This?

`Melodic Stamp` is a macOS music app for local audio files. It plays audio,
edits audio metadata, manages persistent playlists, and displays lyrics in
plain text, `LRC`, and `TTML` formats.

The project is built with SwiftUI and Xcode. `README.md` describes the app as
a free, open-source local music manager and metadata editor that requires
macOS 15 Sequoia or newer.

---

## User Experience

Users open local audio files from Finder, the app menu, drag and drop, or a
file importer. The app can add files to the current playlist, replace the
current playlist, or open the files in a new window.

The main window has a playlist surface and a `Leaflet` surface. The inspector
switches between common metadata, advanced metadata, lyrics, library, and
analytics tabs. A mini-player mode gives the same playback model a compact
window.

Lyrics come from audio metadata. `LyricsModel` recognizes raw text, `LRC`, and
`TTML`, then the lyrics views render line-based or word-based highlighting.

---

## How Is It Organized?

The app is split into an application target, a UI module, and a model module.
The app target creates windows and app-scoped models, then passes those models
into the SwiftUI tree through environment values.

```
User / Finder
  |
  | app launch, file open, drag/drop
  v
MelodicStampApp.swift
  |
  | WindowGroup and Commands
  v
ContentView.swift
  |
  | environment models
  v
InterfaceView.swift
  |
  | SwiftUI surfaces
  v
MainView.swift / MiniPlayerView.swift
  |
  | model calls
  v
PlaylistModel / PlayerModel / MetadataEditorModel
  |
  | files, audio engine, user defaults
  v
SFBAudioEngine / CAAudioHardware / URL.playlists
```

High-level layout:

```
MelodicStampPrototype/
  MelodicStamp/       # App target and app state
  Interface/          # SwiftUI views and commands
  Models/             # Domain models and protocols
  MelodicStampTests/  # App target tests
  InterfaceTests/     # Interface target tests
  ModelsTests/        # Models target tests
  Docs/               # User docs and screenshots
```

| Module | Responsibility |
|--------|----------------|
| `MelodicStamp/MelodicStampApp.swift` | App entry, scenes, commands |
| `MelodicStamp/AppDelegate.swift` | AppKit lifecycle and file opens |
| `MelodicStamp/Models/Content/` | App-scoped observable models |
| `Interface/` | SwiftUI screens, controls, inspectors, toolbars |
| `Models/` | Playlists, tracks, metadata, lyrics, player protocols |
| `MelodicStamp/Utilities/` | Extensions, helpers, window utilities |

External dependencies and integrations:

| Dependency | What it is used for | Configured via |
|------------|---------------------|----------------|
| `SFBAudioEngine` | Audio decoding, playback, metadata IO | Xcode SPM |
| `CAAudioHardware` | Output device discovery and selection | Xcode SPM |
| `Defaults` | Typed user defaults for app settings | Xcode SPM |
| `SwiftSoup` | `TTML` and lyrics markup parsing | Xcode SPM |
| `Swift Collections` | Ordered playlist track indexes | Xcode SPM |
| `DominantColors` | Cover-art color extraction | Xcode SPM |
| `Luminare`, `Morphed` | App UI components and visual effects | Xcode SPM |
| `MeshGradient` | Gradient visualization rendering | Xcode SPM |
| `SFSafeSymbols` | Typed SF Symbols references | Xcode SPM |
| macOS sandbox | Music folder and user-selected files | entitlements |

Persistent playlist data lives under `URL.playlists`, which is built from the
user's music directory, the app display name, and a `Playlists` folder. The app
also registers many audio document types in `Info.plist`.

---

## Key Concepts And Abstractions

| Concept | What it means in this codebase |
|---------|--------------------------------|
| `CreationParameters` | Values used to open a content window |
| `WindowID` | Stable IDs for SwiftUI app windows |
| `MelodicStampWindowStyle` | Main window versus mini-player presentation |
| `Playlist` | A track collection with persisted segments and indexes |
| `referenced` playlist | Playlist backed by original file URLs |
| `canonical` playlist | Playlist copied into the app playlist directory |
| `Track` | A file URL plus its loaded `Metadata` object |
| `Metadata` | Observable wrapper around `AudioMetadata` and properties |
| `MetadataEntry` | Editable initial/current value pair for a metadata field |
| `MetadataEditorProtocol` | Batch update, write, and restore behavior |
| `LyricsModel` | Recognizes and stores parsed lyrics for display |
| `LyricsType` | `raw`, `lrc`, or `ttml` lyrics parsing mode |
| `Player` | Protocol used by `PlayerModel` for playback control |
| `SFBAudioEnginePlayer` | `Player` implementation backed by `SFBAudioEngine` |
| `Indexer` | JSON-backed file index used for playlists and tracks |
| `Defaults.Keys` | Typed settings definitions for app preferences |

The dominant structural pattern is environment-injected observable models.
`ContentView` creates the models, passes them down with `.environment(...)`,
and exposes them to commands with `.focusedValue(...)`.

---

## Primary Flows

Opening and playing audio:

```
User opens or drops audio
  |
  v
MelodicStamp/AppDelegate.swift
  opens a content window for external file URLs
  |
  v
Interface/Functional/Presentations/FileImporters.swift
  accepts app-supported audio and folder selections
  |
  v
MelodicStamp/Models/Content/File Manager/FileManagerModel.swift
  chooses add, replace, play, or new-window behavior
  |
  v
MelodicStamp/Models/Content/Playlist/PlaylistModel.swift
  creates or appends `Track` values
  |
  v
Models/Playlist/Track.swift
  loads `Metadata` for each URL
  |
  v
MelodicStamp/Models/Content/Player/PlayerModel.swift
  drives playback state, commands, and visualization data
  |
  v
Models/Player/SFBAudioEngine/SFBAudioEngine+Player.swift
  creates decoders and plays through `SFBAudioEngine`
```

Editing metadata starts in an inspector view under `Interface/Main/Inspectors/`.
The inspector reads selected tracks through `MetadataEditorModel`, which
implements `MetadataEditorProtocol`. Saving calls `Metadata.write()`, packs
the current entries into `AudioMetadata`, and writes through `SFBAudioEngine`.

Loading lyrics starts from a track's `Metadata.lyrics` entry. `LyricsModel`
detects `LRC` by timestamp tags, detects `TTML` with `SwiftSoup`, and falls
back to raw text. Display views under `Interface/Lyrics/` ask the parser for
highlight ranges based on the current playback time.

Canonical playlist persistence starts with `PlaylistModel.makeCanonical()`.
That migrates referenced tracks into the app playlist directory, writes JSON
segments, writes a `.index` file through `TrackIndexer`, and registers the
playlist in `LibraryModel`.

---

## Developer Guide

Prerequisites:

- macOS with an Xcode version that can build against the macOS 15 SDK.
- Mint, if you want to run the same SwiftFormat command as CI.

Resolve Swift packages:

```sh
xcodebuild \
  -resolvePackageDependencies \
  -project "Melodic Stamp.xcodeproj"
```

Build:

```sh
xcodebuild \
  -project "Melodic Stamp.xcodeproj" \
  -scheme "MelodicStamp" \
  -destination "platform=macOS" \
  build
```

Test:

```sh
xcodebuild \
  -project "Melodic Stamp.xcodeproj" \
  -scheme "MelodicStamp" \
  -destination "platform=macOS" \
  test
```

Format:

```sh
mint run swiftformat --verbose .
```

Common change patterns:

- To change the main app layout, start in `Interface/Main/MainView.swift`.
- To add a menu command, edit `Interface/Functional/Commands/`.
- To change metadata fields, start in `Models/Metadata/Metadata.swift`.
- To change lyrics parsing, work in `Models/Lyrics/` and `LyricsModel`.
- To add settings, add a `Defaults.Keys` entry and a settings control view.
- To change playback, start with `PlayerModel` and the `Player` protocol.

Useful starting points:

| Area | File | Why |
|------|------|-----|
| App entry | `MelodicStamp/MelodicStampApp.swift` | Scenes and commands |
| App lifecycle | `MelodicStamp/AppDelegate.swift` | File open and termination |
| Model wiring | `Interface/ContentView.swift` | Creates environment models |
| Surface routing | `Interface/InterfaceView.swift` | Main vs mini-player |
| Main UI | `Interface/Main/MainView.swift` | Content and inspector tabs |
| File actions | `MelodicStamp/Models/Content/File Manager/FileManagerModel.swift` | Open/add behavior |
| Playlist state | `MelodicStamp/Models/Content/Playlist/PlaylistModel.swift` | Track list mutations |
| Playback | `MelodicStamp/Models/Content/Player/PlayerModel.swift` | Player state and controls |
| Metadata | `Models/Metadata/Metadata.swift` | Metadata load/write path |
| Lyrics | `MelodicStamp/Models/Auxiliary/LyricsModel.swift` | Parser selection |

Practical tips:

- Quote paths with spaces when running shell commands.
- Package resolution may take time because audio dependencies pull native
  binary packages.
- Metadata write paths can change media files. Use temporary files for tests.
- The project uses Xcode file-system synchronized groups with exception sets.
  Check target membership when adding or moving Swift files.
- `Package.resolved` should change only when package pins change.
