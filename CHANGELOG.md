# Changelog

All notable changes to AirTranslate are documented in this file.

## 2026-05-09 - Library Modal UI

### Changed

- Moved saved transcript management out of the sidebar into a focused modal library view.
- Kept the sidebar storage area as a compact entry point for opening saved transcript management.
- Added a saved transcript content selector for original, original plus translation, or translation-only output.
- Added a confirmation-protected delete-all action for saved transcript files.

## 2026-05-09 - MIT Open Source License

### Added

- Added the MIT License as the project license.
- Documented that source code, documentation, scripts, and bundled project assets are covered by the MIT License unless otherwise noted.
- Added README privacy notes describing local-first processing, required permissions, and the absence of app-owned servers, analytics SDKs, or telemetry.

## 2026-05-09 - Transcript Control and Stability

### Added

- Added a settings control for the silence interval that starts a new transcript paragraph.
- The paragraph break interval keeps the previous default of 5 seconds and can now be adjusted from 1 to 15 seconds in 0.5 second steps.

### Changed

- Limited live speech analyzer input buffering to the latest 32 audio chunks so delayed analysis cannot grow an unbounded queue.
- Limited the live translation segment cache to 240 recent entries and reset it when the session, language, or model changes.
- Disabled streaming text animation for long transcript updates to reduce SwiftUI layout and attributed-text work during long sessions.

### Verified

- `swift build` passes.
- Short runtime memory check stabilized around 107 MB RSS after launch.
- `leaks --quiet` reported `0 leaks for 0 total leaked bytes`.
