<blockquote>
  <details>
    <summary>
      <code>あ ←→ A</code>
    </summary>
    <!--Head-->
    &emsp;&ensp;<sub><b>Melodic Stamp</b> supports the following languages. <a href="/Doc/ADD_A_LOCALIZATION.md"><code>↗ Add a localization</code></a></sub>
    <br />
    <!--Body-->
    <br />
    &emsp;&ensp;English
    <br />
    &emsp;&ensp;<a href="/Docs/简体中文.md">简体中文</a>
  </details>
</blockquote>

<div align="center">
  <img width="225" height="225" src="/MelodicStamp/Assets.xcassets/AppIcon.appiconset/icon_512x512%402x.png" alt="Logo">
  <h1><b>Melodic Stamp</b></h1>
  <p>The very choise to play and edit your local audio files, elegantly.<br>
</div>

> [!IMPORTANT]
>
> **Melodic Stamp** requires **macOS 15.0 Sequoia**[^check_your_macos_version] or above to run.

[^check_your_macos_version]: [`↗ Find out which macOS your Mac is using`](https://support.apple.com/en-us/HT201260)

## Overview

**Melodic Stamp** is a music player designed to provide a brand new experience in local music managing and audio metadata editing.
Through an intuitive and elegant interface, you can easily browse and play [various audio formats.](#supported-audio-formats)

<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="/Docs/Contents/English/Main/Playlist/Dark/1.png?raw=true">
    <img src="/Docs/Contents/English/Main/Playlist/Light/1.png?raw=true" width="750" alt="Playlist">
  </picture>
</div>

**Melodic Stamp** also introduces some finely designed interfaces to entertain your journey of music appreciation, such as the ultra smooth lyrics page that comes along with the support of [multiple lyrics formats.](#supported-lyrics-formats)
What's more, it will always be free and open sourced!

### Supported Audio Formats

**Melodic Stamp** is driven by [SFBAudioEngine,](https://github.com/sbooth/SFBAudioEngine) which supports the following audio formats:

- WAV
- AIFF
- CAF
- MP3
- AAC
- m4a
- [FLAC](https://xiph.org/flac)
- [Ogg Opus](https://opus-codec.org)
- [Ogg Speex](https://www.speex.org)
- [Ogg Vorbis](https://xiph.org/vorbis)
- [Monkey's Audio](https://www.monkeysaudio.com)
- [Musepack](https://www.musepack.net)
- Shorten
- True Audio
- [WavPack](http://www.wavpack.com)
- All formats supported by [libsndfile](http://libsndfile.github.io/libsndfile)

### Supported Lyrics Formats

**Melodic Stamp** extracts and parses lyrics from audio metadata into multiple formats for you. The following formats are supported:

- [LRC](<https://en.wikipedia.org/wiki/LRC_(file_format)>)[^extended_lrc_features]
- [TTML](https://en.wikipedia.org/wiki/Timed_Text_Markup_Language)
- Plain text (also the fallback solution for other unsupported formats)

[^extended_lrc_features]: **Melodic Stamp** only accepts some trivial fellow translation lines beyond the original LRC format specification. Other extensions of the LRC format will be parsed as plain LRC lyric lines.

## Features

- **Audio metadata editing**:
  Melodic Stamp allows users to edit the metadata of audio files, including song name, artist, album, cover image, release year, etc. Users can easily manage and update the metadata of music files.

- **Lyrics displaying**:
  Melodic Stamp provides a fabulous and highly interactive lyrics interface. It supports word-based lyrics just like the one used by **Apple Music**[^word_based_lyrics_formats].

[^word_based_lyrics_formats]: In word-based lyrics formats, **Melodic Stamp** only accepts [TTML](https://en.wikipedia.org/wiki/Timed_Text_Markup_Language). To find TTML lyrics, it's recommended to use [AMLL TTML Database](https://github.com/Steve-xmh/amll-ttml-db). You can also create your own lyrics with [AMLL TTML Tool](https://steve-xmh.github.io/amll-ttml-tool/).

- **Playlist**:
  Melodic Stamp provides a persistent playlist function. It supports users to edit the cover, name, and description of playlists, making it convenient to manage and organize music content.

## Screenshots

<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="/Docs/Contents/English/Floating%20Windows/Dark/1.png?raw=true">
    <img src="/Docs/Contents/English/Floating%20Windows/Light/1.png" width="750" alt="Floating Windows">
  </picture>
  <p>Floating Windows</p>
</div>

<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="/Docs/Contents/English/Main/Leaflet/Dark/1.png?raw=true">
    <img src="/Docs/Contents/English/Main/Leaflet/Light/1.png?raw=true" width="750" alt="Leaflet">
  </picture>
  <p>Leaflet</p>
</div>

<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="/Docs/Contents/English/Main/Inspector/Dark/1.png?raw=true">
    <img src="/Docs/Contents/English/Main/Inspector/Light/1.png?raw=true" width="750" alt="Common Metadata Inspector">
  </picture>
  <p>Metadata Editor (Common)</p>
</div>

<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="/Docs/Contents/English/Main/Inspector/Dark/2.png?raw=true">
    <img src="/Docs/Contents/English/Main/Inspector/Light/2.png?raw=true" width="750" alt="Advanced Metadata Inspector">
  </picture>
  <p>Metadata Editor (Advanced)</p>
</div>

<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="/Docs/Contents/English/Main/Inspector/Dark/3.png?raw=true">
    <img src="/Docs/Contents/English/Main/Inspector/Light/3.png?raw=true" width="750" alt="Lyrics Inspector">
  </picture>
  <p>Lyrics Editor</p>
</div>

<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="/Docs/Contents/English/Main/Inspector/Dark/4.png?raw=true">
    <img src="/Docs/Contents/English/Main/Inspector/Light/4.png?raw=true" width="750" alt="Library Inspector">
  </picture>
  <p>Library</p>
</div>

<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="/Docs/Contents/English/Mini%20Player/Dark/1.png?raw=true">
    <img src="/Docs/Contents/English/Mini%20Player/Light/1.png?raw=true" width="750" alt="Mini Player">
  </picture>
  <p>Mini Player</p>
</div>

## Install & Run

> [!NOTE]
>
> **Melodic Stamp** is in active development. You cannot install **Melodic Stamp** directly from the App Store until there is a stable release. At the same time, you may also need to allow **Melodic Stamp** to run as an unauthenticated application[^open_as_unidentified].
>
> For now, you can only download the compressed application file of **Melodic Stamp** from the [Releases](https://github.com/Cement-Labs/MelodicStamp/releases) page.

[^open_as_unidentified]: [`↗ Open a Mac app from an unidentified developer`](https://support.apple.com/guide/mac-help/mh40616/mac)

## QA And Release Readiness

Release-candidate validation is tracked in:

- [`QA_MATRIX.md`](QA_MATRIX.md) for manual product QA coverage.
- [`TEST_ASSETS.md`](TEST_ASSETS.md) for local audio fixture requirements.
- [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) for build, packaging, and go/no-go checks.

Run the local launch smoke before handing a build to testers:

```sh
Scripts/qa_smoke.sh
```
