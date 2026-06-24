# Test Assets

This document defines the local asset library needed to execute `QA_MATRIX.md`.
Do not commit copyrighted audio files into this repository.

## Directory Layout

Create the asset library outside the repo:

```sh
mkdir -p ~/Music/MelodicStampQA/{formats,paths,metadata,lyrics,large,broken}
```

Recommended layout:

```text
~/Music/MelodicStampQA/
  formats/
    common/
    lossless/
    extended/
  paths/
    中文 路径/
    spaced path/
    emoji-🎵/
    punctuation-[]{}!/
  metadata/
    missing-tags/
    rich-tags/
    large-artwork/
    corrupted-artwork/
  lyrics/
    raw/
    lrc/
    ttml/
    malformed/
  large/
    100-tracks/
    1000-tracks/
    10000-tracks/
  broken/
    truncated/
    unreadable/
    unsupported/
```

## Required Asset Sets

| Set | Minimum Contents | Notes |
|-----|------------------|-------|
| Common formats | `mp3`, `m4a`, `aac`, `alac` | Short 10-30 second files are enough for smoke checks |
| Lossless formats | `flac`, `wav`, `aiff` | Include at least one file with embedded artwork |
| Extended formats | `ogg`, `opus`, `ape`, `wv`, `tta`, `mpc` | Use formats supported by the local SFBAudioEngine build |
| Broken files | Truncated audio, invalid extension, unreadable permissions | Verify error paths and import filtering |
| Metadata edge cases | Missing title, non-ASCII tags, large cover, corrupted cover | Verify fallback display and metadata editor behavior |
| Lyrics | Valid `.lrc`, malformed `.lrc`, valid `TTML`, invalid XML, raw text | Use small paired audio files |
| Large libraries | 100, 1,000, 10,000 file folders | Files may be generated silent clips or duplicated legal fixtures |

## Generating Legal Smoke Files

Use generated tones or silence for repeatable QA. Example with `afconvert`:

```sh
mkdir -p ~/Music/MelodicStampQA/formats/common
say -o /tmp/melodic-smoke.aiff "Melodic Stamp QA smoke track"
afconvert /tmp/melodic-smoke.aiff ~/Music/MelodicStampQA/formats/common/smoke.m4a -f m4af -d aac
afconvert /tmp/melodic-smoke.aiff ~/Music/MelodicStampQA/formats/lossless/smoke.wav -f WAVE -d LEI16
```

For MP3, FLAC, OGG, Opus, and other formats, use legally generated fixtures
from a local encoder or public-domain samples. Record the source and license
in `~/Music/MelodicStampQA/SOURCES.md`.

## Manual QA Recording

For each release candidate, create a dated result file outside the repo:

```sh
mkdir -p ~/Music/MelodicStampQA/results
cp QA_MATRIX.md ~/Music/MelodicStampQA/results/$(date +%Y-%m-%d)-qa.md
```

Fill each row with `Pass`, `Fail`, `Blocked`, or `N/A`, plus:

- App commit SHA.
- macOS version.
- Xcode version.
- Hardware model and CPU architecture.
- Audio output device.
- Asset set path and version.

## Asset Hygiene

- Never commit copyrighted audio.
- Prefer short generated clips for automated smoke checks.
- Keep large libraries outside the repository.
- Keep broken files clearly labeled to avoid accidental playback confusion.
- When a bug depends on one asset, record the filename, format, duration, and
  metadata summary in the issue.
