# AirTranslateX

macOS live transcription and translation app.

## Requirements

- macOS 26.0 or later
- Swift 6.2 or later
- Xcode command line tools

## Build And Run

```bash
./script/build_and_run.sh
```

Build and verify that the app launches:

```bash
./script/build_and_run.sh --verify
```

View logs:

```bash
./script/build_and_run.sh --logs
```

Reset local development permissions:

```bash
./script/build_and_run.sh --reset-permissions
```

## Test

```bash
swift build
swift test
```

## Permissions

The app needs these macOS permissions for capture and transcription:

- Screen Recording
- System Audio Recording
- Speech Recognition
- Microphone, only when microphone input is selected

After changing permissions, quit and relaunch the app.

## API Keys

API keys are stored in macOS Keychain. The app supports:

- OpenAI-compatible chat completion APIs
- OpenRouter
- AiHubMix
- Deepgram
- Google Cloud Translation
- DeepL Free and DeepL Pro

## Useful Paths

Saved transcripts:

```text
~/Library/Application Support/AirTranslate/Transcripts/
```

Local app bundle:

```text
dist/AirTranslateX.app
```

## Project Map

```text
Package.swift
Resources/
Sources/AirTranslate/
Sources/AirTranslateCore/
Tests/
script/
```

## License

See [LICENSE](LICENSE).
