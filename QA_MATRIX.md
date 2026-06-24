# QA Matrix

This matrix defines the minimum product QA coverage before treating Melodic
Stamp as release-candidate quality.

## Result Legend

| Result | Meaning |
|--------|---------|
| Pass | Works as expected |
| Fail | Reproducible defect |
| Blocked | Cannot test because an input, tool, or environment is missing |
| N/A | Not applicable for the current build |

## Audio Format Coverage

| Area | Cases | Expected Result | Priority |
|------|-------|-----------------|----------|
| Common compressed audio | `mp3`, `m4a`, `aac`, `alac` | Import, metadata load, play, pause, seek, and end-of-track transition work | P0 |
| Lossless audio | `flac`, `wav`, `aiff` | Duration, waveform time, seeking, and metadata display are correct | P0 |
| Extended SFBAudioEngine formats | `ogg`, `opus`, `ape`, `wv`, `tta`, `mpc`, tracker/module formats | Unsupported files are rejected cleanly; supported files play without UI lockups | P1 |
| Damaged or partial files | Truncated file, invalid header, unreadable decoder | Playback error appears, app stays responsive, next valid track still plays | P0 |
| Large files | 30 min, 2 hr, and high-bitrate files | Seek and progress updates stay responsive | P1 |

## File Access And Path Coverage

| Area | Cases | Expected Result | Priority |
|------|-------|-----------------|----------|
| Path names | Chinese, Japanese, emoji, spaces, punctuation, very long names | Import and playback work; UI text does not overflow critical controls | P0 |
| Locations | Music folder, Downloads, Desktop, external drive, iCloud Drive | Security-scoped access starts and stops correctly | P0 |
| Missing files | Move/delete imported tracks, unplug external drive | Track is marked or reported as unavailable; app does not crash | P0 |
| Permission loss | Revoke folder access or open stale bookmark | Recovery/error message is actionable | P1 |
| Folder import | Flat folder, nested folder, mixed supported/unsupported files | Supported tracks import; unsupported files do not block import | P0 |

## Playback Flow Coverage

| Area | Cases | Expected Result | Priority |
|------|-------|-----------------|----------|
| Basic transport | Play, pause, resume, previous, next | UI state matches engine state | P0 |
| Seeking | Click progress bar, drag progress, seek near end | Time display, Now Playing, and engine time remain consistent | P0 |
| Playback modes | Off, list repeat, single repeat | Button cycles reliably; playback behavior matches selected mode | P0 |
| Queue edges | Empty list, single track, last track, removed current track | Controls are disabled or recover gracefully | P0 |
| Resume playback | Relaunch with saved current track and elapsed time | Playback resumes from saved position only for matching track | P1 |
| Output devices | Refresh devices, select unavailable device, unplug device | Error is shown once until recovery; playback can continue on valid device | P1 |

## Library And Playlist Coverage

| Area | Cases | Expected Result | Priority |
|------|-------|-----------------|----------|
| Empty library | First launch, no playlists | Useful empty state with import actions | P0 |
| Small playlists | 1, 2, 10 tracks | Selection, highlight, metadata, and playback work | P0 |
| Large playlists | 100, 1,000, 10,000 tracks | UI remains responsive; indexing does not block main thread noticeably | P1 |
| Persistence | Quit/reopen, canonical playlist reload, referenced playlist reload | Tracks, selection, playback mode, and state restore correctly | P0 |
| Duplicates | Same file added multiple times, same title different URL | App preserves distinct URLs and does not corrupt indexes | P1 |
| Mutation | Delete, reorder, append, replace, clear | Index files and playlist segments stay consistent | P0 |

## Metadata And Artwork Coverage

| Area | Cases | Expected Result | Priority |
|------|-------|-----------------|----------|
| Common metadata | Title, artist, album, track number, disc number, genre, date | List, player, inspector, and Now Playing use current values | P0 |
| Missing metadata | Untagged track, empty title, empty artist | Filename fallback is readable | P0 |
| Metadata editing | Single edit, batch edit, save failure, revert | Dirty state and errors are clear; failed save does not lose user edits | P0 |
| Artwork | No art, small art, large art, corrupted art | Cover UI falls back safely; large art does not freeze UI | P1 |
| Encoding | Mojibake tags, mixed-language tags | UI displays best available string without crashing | P1 |

## Lyrics Coverage

| Area | Cases | Expected Result | Priority |
|------|-------|-----------------|----------|
| No lyrics | Track without lyrics | Lyrics surface shows a useful empty state | P1 |
| Raw lyrics | Plain text embedded lyrics | Display renders without timing expectations | P1 |
| LRC | Standard timestamps, translations, malformed lines | Parser skips bad lines and keeps later valid lyrics | P0 |
| TTML | Word timing, line timing, invalid markup | Valid TTML renders; invalid TTML reports lyrics error only | P1 |
| Local files | Same-name `.lrc` and selected external lyrics file | Loader handles UTF-8 and reports unreadable encodings | P1 |

## Window And UI Stability Coverage

| Area | Cases | Expected Result | Priority |
|------|-------|-----------------|----------|
| Main window | Cold launch, relaunch, resize, close, reopen | No AppKit constraint loop or unexpected quit | P0 |
| Mini player | Switch to mini player, back to main, resize constraints | Playback state is preserved; dimensions are stable | P0 |
| Floating controls | Main window launch, resize, move, full screen, multi-display | Floating windows appear after main window stabilizes and never crash launch | P0 |
| Auxiliary windows | Settings, About, alerts, file importer | Windows open and close without blocking playback | P1 |
| Localization | English and Simplified Chinese UI | Window title and key actions are readable | P1 |

## Lifecycle Coverage

| Area | Cases | Expected Result | Priority |
|------|-------|-----------------|----------|
| Relaunch | Quit while idle, quit while playing, force quit | State restores safely; playback does not auto-start unless requested | P0 |
| Sleep/wake | Sleep during playback, wake with device changes | App remains responsive and output devices can refresh | P1 |
| System media | Now Playing info, media keys, command menu shortcuts | Commands map to current focused player | P1 |
| App termination | Unsaved playlist or metadata changes | User can cancel or confirm; app does not hang termination | P0 |

## Performance Coverage

| Area | Cases | Expected Result | Priority |
|------|-------|-----------------|----------|
| Import throughput | 100, 1,000, 10,000 files | Main UI remains usable; progress or status is visible | P1 |
| Metadata load | Mixed formats and missing tags | Failures are aggregated and visible | P1 |
| Visualizers | Spectrum, gradient, reduced motion/performance settings | Frame rate is acceptable; settings reduce load | P2 |
| Memory | Large playlists, large artwork, long playback session | Memory stabilizes after import/playback operations | P1 |

## Release Candidate Gate

A build can be called a release candidate only when:

- All P0 rows are Pass or have documented accepted risk.
- No launch, playback, import, or persistence crash is known.
- `xcodebuild test` passes on a clean checkout.
- A signed app has passed three cold-launch cycles from `/Applications`.
- Any failing P1 rows have issues filed with reproduction steps.
