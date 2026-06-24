# AGENTS.md

## Scope

These instructions apply to the whole repository.

## Project Snapshot

`Melodic Stamp` is a macOS SwiftUI app for playing local audio files,
editing audio metadata, managing playlists, and displaying lyrics. The Xcode
project is `Melodic Stamp.xcodeproj`, and the app target is `Melodic Stamp`.

The main code areas are:

| Path | Purpose |
|------|---------|
| `MelodicStamp/` | App entry point, app-level models, resources, utilities |
| `Interface/` | SwiftUI views, commands, toolbars, presentation helpers |
| `Models/` | Shared domain models, metadata, lyrics, player protocols |
| `MelodicStampTests/` | Tests for the app target |
| `InterfaceTests/` | Tests for the `Interface` framework target |
| `ModelsTests/` | Tests for the `Models` framework target |
| `Docs/` | User-facing docs, screenshots, localization docs |

Read `ONBOARDING.md` before making broad changes.

## Build, Test, And Format

This project requires macOS and Xcode with a macOS 15 SDK. The app runtime
requirement documented in `README.md` is macOS 15 Sequoia or newer.

Resolve packages:

```sh
xcodebuild \
  -resolvePackageDependencies \
  -project "Melodic Stamp.xcodeproj"
```

Build the debug app:

```sh
xcodebuild \
  -project "Melodic Stamp.xcodeproj" \
  -scheme "MelodicStamp" \
  -destination "platform=macOS" \
  build
```

Run all tests attached to the main scheme:

```sh
xcodebuild \
  -project "Melodic Stamp.xcodeproj" \
  -scheme "MelodicStamp" \
  -destination "platform=macOS" \
  test
```

Format Swift code:

```sh
mint run swiftformat --verbose .
```

`Mintfile` currently pins the tool dependency to `nicklockwood/SwiftFormat`.
The GitHub workflow in `.github/workflows/mint.yml` runs SwiftFormat on pushes
and pull requests.

## Working Rules For Agents

- Quote paths that contain spaces, especially `Melodic Stamp.xcodeproj` and
  directories such as `Interface/Floating Windows/`.
- Use `rg` or `rg --files` for searches.
- Keep source changes scoped to the owning module. UI views usually belong in
  `Interface/`; reusable domain logic belongs in `Models/`; app lifecycle and
  app-scoped state belong in `MelodicStamp/`.
- The project uses SwiftUI's Observation APIs (`@Observable`) and injects
  model instances through SwiftUI environment values. Follow that pattern for
  new app state instead of introducing global singletons.
- Many user actions flow through focused values and SwiftUI `Commands` in
  `Interface/Functional/Commands/`. Check those files when changing keyboard
  shortcuts, menus, player actions, or file actions.
- Metadata writes can modify real audio files. Tests and manual checks should
  use temporary copies or fixtures, never a user's only copy of a media file.
- If adding Swift files, verify target membership in Xcode. The project uses
  Xcode file-system synchronized groups with exception sets, so filesystem
  placement and target membership still matter.
- Do not edit `Package.resolved` unless package dependencies intentionally
  change.
- Leave local or generated state alone unless the user asks for it. This
  includes `xcuserdata/`, `.DS_Store`, and local agent directories such as
  `.nezha/`.

## Common Change Patterns

- New UI surface: start from `Interface/Main/MainView.swift`, then place
  focused views under the relevant `Interface/` subdirectory.
- New menu or shortcut: edit the matching file in
  `Interface/Functional/Commands/`.
- New metadata field: update `Models/Metadata/Metadata.swift`,
  `Models/Metadata/MetadataEntry.swift`, and the relevant inspector view.
- New lyric parsing behavior: work in `Models/Lyrics/` and
  `MelodicStamp/Models/Auxiliary/LyricsModel.swift`.
- New persisted setting: add a key in
  `MelodicStamp/Utilities/Extensions/Defaults+Extensions.swift`, then add UI
  under `Interface/Settings/`.
- New playback behavior: check `Models/Player/`, then the app-facing
  `MelodicStamp/Models/Content/Player/PlayerModel.swift`.

## Review Checklist

Before handing work back:

- Run the narrowest useful `xcodebuild` command when source code changed.
- Run `mint run swiftformat --verbose .` when Swift code changed.
- Add or update Swift Testing tests when behavior changes.
- Check `git diff --stat` and make sure no unrelated local files were touched.
