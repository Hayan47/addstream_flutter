# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.1] - 2026-02-22
### Fixed
- Improved fullscreen video player UI and controls
- Fixed video margin and loading widget display issues
- Enhanced video end card layout and responsiveness

---

## [1.2.0] - 2026-02-19
### Added
- `VideoEndCard` overlay displayed when the video completes — shows the last visible frame, a Replay button, and a Visit Site button (only when a click-through URL is present); re-appears automatically after replay finishes
- `onVideoReady` callback on `AddStreamVideoWidget` — fires once the first video frame is rendered on screen, distinct from `onAdLoaded` which fires after initialization
- `onImageLoaded` callback on `AddStreamWidget` — fires when the ad image pixels are fully decoded and painted on screen

### Fixed
- Pause and resume IAB tracking events are now deduplicated with a `markEventFired` guard to prevent double-firing

---

## [1.1.0] - 2026-02-17
### Added
- `AddStreamVideoWidget` for displaying VAST video advertisements
- Full IAB VAST 2.0 tracking event support (start, firstQuartile, midpoint, thirdQuartile, complete, pause, resume, mute, unmute, fullscreen, click, stop, replay)
- Automatic impression firing on ad load
- Mute/unmute, play/pause, and fullscreen controls
- Progress bar overlay on video ad
- `onTrackingEvent` callback for monitoring ad events externally
- `onAdClosed` callback when the user dismisses the video ad
- HMAC-SHA256 authentication on VAST requests (consistent with banner ads)

### Changed
- `AnimatedAdBadge` extracted to shared widget used by both `AddStreamWidget` and `AddStreamVideoWidget`

## [1.0.3] - 2025-10-16
### Removed
- Fix AddStream logo click
- Minor documentation updates

## [1.0.2] - 2025-10-15
### Removed
- Removed `onAdClicked` callback (deprecated before stable release).
- Minor improvements to documentation.

## [1.0.1] - 2025-10-14
### Fixed
- Minor documentation and metadata updates.

## [1.0.0] - 2025-10-14
### Added
- Initial release of AddStream Flutter package
- `AddStreamWidget` for displaying ads
- `AddStreamGlobal.initialize()` for SDK initialization
- Support for image and text ad formats
- Animated badge overlay on ads
- Custom loading and error widget support
- Callback system for ad events (loaded, clicked, failed)
- `AddStreamException` for proper error handling
- Automatic impression tracking
- Click handling with external browser launch

### Features
- Zone-based ad serving
- Responsive ad sizing
- Network error handling
- Debug mode warnings
- Graceful fallbacks for missing ads

### Dependencies
- http: ^1.1.0
- html: ^0.15.4
- url_launcher: ^6.2.0
- crypto: ^3.0.6

---

## Version Format

[MAJOR.MINOR.PATCH]

- **MAJOR**: Breaking changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes (backwards compatible)