# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

## [Unreleased]

### Planned
- Video ad support
- Ad caching mechanism
- Advanced targeting options
- Analytics dashboard integration

---

## Version Format

[MAJOR.MINOR.PATCH]

- **MAJOR**: Breaking changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes (backwards compatible)