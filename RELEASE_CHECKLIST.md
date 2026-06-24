# Release Checklist

Use this checklist before distributing a build outside a local development
machine.

## Build Identity

- [ ] Version and build number are updated.
- [ ] Commit SHA is recorded.
- [ ] Release notes describe user-visible changes and known issues.
- [ ] Third-party dependency changes are reviewed.

## Build And Test

- [ ] Clean checkout builds in Debug.
- [ ] Clean checkout builds in Release.
- [ ] Full test suite passes:

```sh
xcodebuild \
  -project "Melodic Stamp.xcodeproj" \
  -scheme MelodicStamp \
  -configuration Debug \
  -destination "platform=macOS" \
  CODE_SIGNING_ALLOWED=NO \
  test
```

- [ ] Release app launches from `/Applications` three times without crash.
- [ ] Recent system logs contain no `NSGenericException` or AppKit constraint
  loop for `Melodic Stamp`.
- [ ] Local release smoke passes:

```sh
Scripts/qa_smoke.sh
```

- [ ] Manual QA P0 rows in `QA_MATRIX.md` pass.

## Product QA

- [ ] First-run empty state is clear and offers import actions.
- [ ] File import reports success, partial failure, and unsupported files.
- [ ] Playback transport works for empty list, one track, many tracks, and
  damaged current track.
- [ ] Repeat mode cycles through off, list repeat, and single repeat.
- [ ] Playlist state persists across relaunch.
- [ ] Metadata editing save failure preserves unsaved user edits.
- [ ] Lyrics parsing failure does not block playback.
- [ ] Mini player switches to and from main window without losing playback
  state.
- [ ] Floating windows do not appear until the main window is stable.

## Packaging

- [ ] App is signed with a Developer ID Application certificate.
- [ ] App is notarized by Apple.
- [ ] Stapled notarization ticket is verified.
- [ ] DMG or ZIP artifact is created.
- [ ] Artifact checksum is recorded.
- [ ] Fresh install works on a clean macOS account.
- [ ] Upgrade install preserves existing library state.

## Compliance And Support

- [ ] Privacy and permissions text is reviewed.
- [ ] Third-party licenses are collected.
- [ ] Open-source notices are included in the release artifact or docs.
- [ ] Crash/reporting instructions are documented.
- [ ] Known issue list is included in release notes.

## Go / No-Go

Ship only when:

- [ ] No known P0 defect remains.
- [ ] No launch crash or playback crash remains.
- [ ] QA owner signs off on the dated QA result file.
- [ ] Product owner signs off on known issues.
