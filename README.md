# AddStream Flutter

A Flutter package for integrating AddStream ads into your mobile applications.
To learn more about AddStream, please visit the [AddStream website](https://addstream.net/)

[![pub.dev](https://img.shields.io/pub/v/addstream_flutter.svg)](https://pub.dev/packages/addstream_flutter)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Features

- **Banner Ads** — Display image and GIF banner ads with automatic impression tracking
- **VAST Video Ads** — Full IAB VAST 2.0 video ad support with play/pause, mute, and fullscreen controls
- **IAB Tracking Events** — Automatic firing of start, quartile, complete, and all standard VAST events
- **Secure** — HMAC-SHA256 request signing on all API calls
- **Customizable** — Custom loading and error widgets for both ad formats
- **Cross-Platform** — iOS and Android

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  addstream_flutter: ^1.2.3
```

Then run:

```bash
flutter pub get
```

## Platform Configuration

### Android

Add internet permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

For URL launching support, add inside the `<manifest>` tag:

```xml
<queries>
    <intent>
        <action android:name="android.support.customtabs.action.CustomTabsService" />
    </intent>
</queries>
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>https</string>
    <string>http</string>
</array>
```

## Quick Start

### 1. Initialize AddStream

Call `AddStreamGlobal.initialize()` in `main()` before `runApp()`:

```dart
import 'package:flutter/material.dart';
import 'package:addstream_flutter/addstream_flutter.dart';

void main() {
  AddStreamGlobal.initialize(
    AddStreamConfig(
      apiUrl: 'https://your-api-url.com',
      apiKey: 'your-api-key',
      videoApiUrl: 'https://your-video-api-url.com', // required for video ads
    ),
  );

  runApp(const MyApp());
}
```

> **Note:** Forgetting to call `initialize()` will show a descriptive error in debug mode so you can catch it early.

### 2. Add a Banner Ad

```dart
AddStreamWidget(
  zoneId: 'your-zone-id',
  width: 320,
  height: 50,
  margin: const EdgeInsets.symmetric(vertical: 8),
  onAdLoaded: () => debugPrint('Ad loaded'),
  onAdFailed: (error) => debugPrint('Ad failed: $error'),
)
```

### 3. Add a Video Ad

```dart
AddStreamVideoWidget(
  zoneId: 'your-video-zone-id',
  margin: const EdgeInsets.symmetric(vertical: 8),
  onAdLoaded: () => debugPrint('Video ad loaded'),
  onAdFailed: (error) => debugPrint('Video ad failed: $error'),
  onAdClosed: () => debugPrint('Video ad closed'),
  onTrackingEvent: (event) => debugPrint('Event fired: $event'),
)
```

## Usage Examples

### Banner Ad with Custom Widgets

```dart
AddStreamWidget(
  zoneId: 'your-zone-id',
  width: 320,
  height: 50,
  loadingWidget: const SizedBox(
    height: 50,
    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
  ),
  errorWidget: const SizedBox.shrink(), // hide when no ad available
  onAdLoaded: () {
    // track in your analytics
  },
  onAdFailed: (error) {
    // log or handle silently
  },
)
```

### Video Ad with Custom Loading Widget

```dart
AddStreamVideoWidget(
  zoneId: 'your-video-zone-id',
  borderRadius: 12,
  loadingWidget: const SizedBox(
    height: 200,
    child: Center(child: CircularProgressIndicator()),
  ),
  onTrackingEvent: (event) {
    // events: start, firstQuartile, midpoint, thirdQuartile,
    //         complete, pause, resume, mute, unmute,
    //         fullscreen, click, stop, replay
    if (event == 'complete') {
      // reward the user
    }
  },
)
```

## API Reference

### AddStreamGlobal.initialize()

Must be called once before using any widgets, typically in `main()`.

```dart
AddStreamGlobal.initialize(
  AddStreamConfig(
    apiUrl: 'https://your-api-url.com',
    apiKey: 'your-api-key',
    videoApiUrl: 'https://your-video-api-url.com',
    timeout: const Duration(seconds: 10),
  ),
);
```

### AddStreamConfig

| Property      | Type      | Required | Default      | Description                              |
|---------------|-----------|----------|--------------|------------------------------------------|
| `apiUrl`      | `String`  | Yes      | —            | Base URL for the banner ad API           |
| `apiKey`      | `String`  | Yes      | —            | API key for HMAC authentication          |
| `videoApiUrl` | `String?` | No       | `null`       | Base URL for the VAST video API          |
| `timeout`     | `Duration`| No       | 10 seconds   | Request timeout for all API calls        |

### AddStreamWidget

| Parameter       | Type                   | Required | Default | Description                          |
|-----------------|------------------------|----------|---------|--------------------------------------|
| `zoneId`        | `String`               | Yes      | —       | Ad zone ID provided by AddStream     |
| `width`         | `double?`              | No       | `400`   | Ad width in logical pixels           |
| `height`        | `double?`              | No       | `100`   | Ad height in logical pixels          |
| `margin`        | `EdgeInsetsGeometry?`  | No       | `null`  | Margin around the widget             |
| `borderRadius`  | `double`               | No       | `8.0`   | Corner radius of the ad container    |
| `loadingWidget` | `Widget?`              | No       | `null`  | Shown while the ad is loading        |
| `errorWidget`   | `Widget?`              | No       | `null`  | Shown when no ad is available        |
| `onAdLoaded`    | `VoidCallback?`        | No       | `null`  | Called when the API response is received and the ad is ready |
| `onImageLoaded` | `VoidCallback?`        | No       | `null`  | Called when the ad image is fully decoded and painted on screen |
| `onAdFailed`    | `Function(Object)?`    | No       | `null`  | Called when the ad fails to load     |

### AddStreamVideoWidget

| Parameter        | Type                   | Required | Default | Description                                      |
|------------------|------------------------|----------|---------|--------------------------------------------------|
| `zoneId`         | `String`               | Yes      | —       | Video zone ID provided by AddStream              |
| `margin`         | `EdgeInsetsGeometry?`  | No       | `null`  | Margin around the widget                         |
| `borderRadius`   | `double`               | No       | `8.0`   | Corner radius of the video container             |
| `loadingWidget`  | `Widget?`              | No       | `null`  | Shown while the video is loading                 |
| `errorWidget`    | `Widget?`              | No       | `null`  | Shown when the video fails to load               |
| `onAdLoaded`     | `VoidCallback?`        | No       | `null`  | Called when the VAST response is parsed and the video is initialized |
| `onVideoReady`   | `VoidCallback?`        | No       | `null`  | Called when the first video frame is rendered on screen |
| `onAdFailed`     | `Function(Object)?`    | No       | `null`  | Called when the video fails to load              |
| `onAdClosed`     | `VoidCallback?`        | No       | `null`  | Called when the user dismisses the ad            |
| `onTrackingEvent`| `Function(String)?`    | No       | `null`  | Called for each IAB VAST tracking event          |

**Tracking events:** `start`, `firstQuartile`, `midpoint`, `thirdQuartile`, `complete`, `pause`, `resume`, `mute`, `unmute`, `fullscreen`, `click`, `stop`, `replay`

**Video end card:** When the video completes, an overlay is shown with a Replay button and, if the ad has a click-through URL, a Visit Site button. The end card re-appears after each replay.

### AddStreamException

Thrown for programmer errors (e.g. widget used before `initialize()` is called). In debug mode this produces a descriptive red screen. In release mode the widget falls back silently.

```dart
onAdFailed: (error) {
  if (error is AddStreamException) {
    print(error.message);
  }
}
```

## Error Handling

| Scenario | Debug | Release |
|---|---|---|
| `initialize()` not called | Red error screen | Silent fallback |
| `videoApiUrl` not set (video widget) | Red error screen | Silent fallback |
| API / network error | `onAdFailed` callback + log | `onAdFailed` callback |
| No ad inventory for zone | `onAdFailed` callback | `onAdFailed` callback |

## Common Issues

**"AddStream not initialized" error**
Call `AddStreamGlobal.initialize()` before `runApp()` in `main()`.

**Video ad not showing**
Ensure `videoApiUrl` is set in `AddStreamConfig`. Omitting it while using `AddStreamVideoWidget` will throw in debug mode.

**No ad appearing**
This is expected when there is no inventory for your zone. The widget shows `errorWidget` or hides itself.

## Dependencies

| Package         | Version   |
|-----------------|-----------|
| `http`          | ^1.5.0    |
| `html`          | ^0.15.6   |
| `xml`           | ^6.5.0    |
| `url_launcher`  | ^6.3.2    |
| `crypto`        | ^3.0.6    |
| `video_player`  | ^2.10.1   |
| `audio_session` | ^0.1.0    |

## Requirements

- Dart: >=3.0.0
- Flutter: >=1.17.0

## License

MIT — see [LICENSE](LICENSE) for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.