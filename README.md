![AirTranslate hero](docs/assets/airtranslate-readme-hero.png)

# AirTranslate

Live system-audio transcription and translation for macOS.

[![macOS 26+](https://img.shields.io/badge/macOS-26%2B-0A84FF?style=flat-square&logo=apple)](#requirements)
[![Swift 6.2+](https://img.shields.io/badge/Swift-6.2%2B-F05138?style=flat-square&logo=swift&logoColor=white)](#build-from-source)
[![SwiftPM](https://img.shields.io/badge/SwiftPM-enabled-24292F?style=flat-square)](#project-map)
[![Latest Release](https://img.shields.io/github/v/release/himomohi/AirTranslate?style=flat-square&label=release)](https://github.com/himomohi/AirTranslate/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/himomohi/AirTranslate/total?style=flat-square&label=downloads)](https://github.com/himomohi/AirTranslate/releases/latest)
[![Download ZIP](https://img.shields.io/badge/download-AirTranslate--1.2.1.zip-2EA44F?style=flat-square&logo=github)](https://github.com/himomohi/AirTranslate/releases/latest/download/AirTranslate-1.2.1.zip)
[![Version History](https://img.shields.io/badge/version%20history-Release%2FVERSION--HISTORY.md-6E56CF?style=flat-square)](Release/VERSION-HISTORY.md)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue?style=flat-square)](LICENSE)

**Languages:** English | [한국어](README.ko.md) | [日本語](README.ja.md) | [中文](README.zh-CN.md)

AirTranslate captures audio playing on your Mac, turns it into a live transcript, translates it in real time, and can show the result as a floating caption overlay. It is designed for meetings, lectures, videos, interviews, and streams where routing audio through a microphone is awkward or lossy.

The default workflow uses Apple frameworks. GPT-powered realtime models are optional and can be enabled from the app when you provide your own OpenAI API key.

## Why AirTranslate

- **System-audio first:** capture Mac playback audio directly with ScreenCaptureKit.
- **Readable live workspace:** source and translated text stay side by side.
- **Floating captions:** keep subtitles above other apps while you watch or listen.
- **Apple by default:** Apple Speech and Apple Translation remain the baseline path.
- **Optional GPT mode:** OpenAI Realtime transcription and translation can be enabled only when needed.
- **Keychain storage:** OpenAI API keys are entered by the user and stored in macOS Keychain.
- **Plain text history:** saved transcripts remain normal `.txt` files in Application Support.

## Core Features

- Live Mac system-audio capture
- Apple Speech transcription
- Apple Translation output
- GPT mode with OpenAI Realtime transcription and translation
- Realtime translation-only model path
- One-click source/target language swap
- Floating caption window
- Transcript polish based on macOS spelling suggestions
- Optional translated speech output
- Saved transcript library with edit, delete, and folder access
- English, Korean, Japanese, and Simplified Chinese interface selection based on the Mac language

## Processing Modes

AirTranslate separates the quick choice from the detailed setup.

| Mode | Best For | Details |
| --- | --- | --- |
| Apple Mode | Local-first transcription and translation | Uses Apple Speech for transcription and Apple Translation for the selected language pair. |
| GPT Mode | OpenAI Realtime transcription or translation | Enables GPT realtime models. If no API key is saved, AirTranslate opens the settings modal and focuses the API key field. |
| Transcribe Only | Source captions without translation | Records source-language captions without running translation. |
| Realtime Translation Only | Direct translated stream | Uses the realtime translation model path when you want the model to produce the translated stream directly. |

GPT model details, API key entry, transcript polish, and voice output are managed from the gear-shaped settings modal. The main sidebar only exposes the most important choices.

## Privacy And API Keys

AirTranslate does not ship with a backend account system.

- Apple Mode uses macOS frameworks and locally managed Apple language assets.
- OpenAI calls happen only when GPT mode or OpenAI translation models are enabled.
- OpenAI API keys are never hardcoded, committed, or included in release packages.
- Keys are saved in macOS Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
- Saved transcripts are plain text files on your Mac.

Need an API key? Open the [OpenAI API key page](https://platform.openai.com/api-keys), create a key, then paste it into AirTranslate's settings modal.

## Apple Translation Language Packs

Apple Mode uses macOS-managed translation languages. Before using Apple Mode with a new language pair, download the needed Apple translation language packs:

1. Open **System Settings**.
2. Go to **General > Language & Region**.
3. Click **Translation Languages**.
4. Click **Download** for each source and target language you want to use.
5. Optional: turn on **On-Device Mode** if you want macOS to process supported translations on your Mac whenever possible.

If a selected language pair is unavailable or not downloaded, Apple Mode translation may not start or may show an unavailable state until macOS has the required language assets.

## Permissions

AirTranslate asks for the permissions required by its capture and transcription flow.

- Screen Recording
- System Audio Recording
- Speech Recognition

Screen Recording is required because ScreenCaptureKit provides the system-audio capture path. AirTranslate does not save screen frames as recordings.

After changing macOS privacy permissions, quit and relaunch the app so the signed app bundle receives the new authorization state.

## Download

Download the latest open-source build from [GitHub Releases](https://github.com/himomohi/AirTranslate/releases/latest), or download the ZIP directly:

- [Download AirTranslate-1.2.1.zip](https://github.com/himomohi/AirTranslate/releases/latest/download/AirTranslate-1.2.1.zip)
- [View version history](Release/VERSION-HISTORY.md)

The release ZIP is ad-hoc signed for open-source distribution. macOS may ask you to approve it in Privacy & Security before first launch.

## Requirements

- macOS 26.0 or later
- Swift 6.2 or later
- A Mac that supports system-audio capture
- Apple Speech and Apple Translation framework availability
- Optional: an OpenAI API key for GPT mode

## Build From Source

Run the app bundle:

```bash
./script/build_and_run.sh
```

Build and verify launch:

```bash
./script/build_and_run.sh --verify
```

View logs:

```bash
./script/build_and_run.sh --logs
```

Reset development permissions:

```bash
./script/build_and_run.sh --reset-permissions
```

SwiftPM checks:

```bash
swift build
swift test
```

## Basic Usage

1. Choose the source and target languages.
2. Use the center swap button if you want to reverse the direction.
3. Choose Apple Mode or GPT Mode.
4. For GPT Mode, add your OpenAI API key in the settings modal if prompted.
5. Press Start.
6. Play meeting, lecture, video, interview, or stream audio on your Mac.
7. Read the transcript and translation in the main workspace or floating caption window.
8. Press Stop to save the current transcript.

## Saved Transcripts

Saved transcripts are stored as plain text files:

```text
~/Library/Application Support/AirTranslate/Transcripts/*.txt
```

When source and translation are saved together, AirTranslate writes separate `_original.txt` and `_translation.txt` files while presenting them as one grouped item in the library UI.

## Project Map

```text
Package.swift
Resources/
  AppIcon.png
  AppIcon.icns
Sources/AirTranslate/
  App/
  Models/
  Services/
  Support/
  Views/
Sources/AirTranslateCore/
Tests/
script/
  build_and_run.sh
docs/assets/
  airtranslate-readme-hero.png
```

## Key Implementation Areas

- `SystemAudioCapture`: captures Mac system audio through ScreenCaptureKit.
- `LiveSpeechTranscriber`: streams speech recognition through Apple Speech.
- `AppleTranslationService`: isolates Apple Translation work.
- `OpenAIRealtimeTranscriber`: handles optional realtime transcription.
- `OpenAITranslationService`: handles optional realtime translation requests.
- `OpenAIAPIKeyStore`: saves the API key in macOS Keychain.
- `TranslationSessionStore`: coordinates capture, transcript state, translation, saving, and playback.
- `SidebarView`: language, mode, session, and settings entry points.
- `CaptionBoardView`: live transcript, translation, controls, and audio meter.
- `TranscriptLibraryView`: saved transcript management.
- `FloatingCaptionWindowController`: floating subtitle window lifecycle.

## License

AirTranslate is released under the [Apache License 2.0](LICENSE). Copyright attribution is provided in [NOTICE](NOTICE).

AirTranslate is an independent open-source project and is not affiliated with Apple or OpenAI.
