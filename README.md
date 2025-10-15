# AddStream Flutter

A Flutter package for integrating AddStream ads into your mobile applications.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Features

✨ **Easy Integration** - Simple widget-based API  
🎯 **Multiple Ad Formats** - Support for image and GIF ads  
⚡ **Fast & Lightweight** - Minimal dependencies  
🔒 **Private & Secure** - Uses HMAC-SHA256 signature for authentication  
📱 **Cross-Platform** - Works on iOS and Android  
🎨 **Customizable** - Custom loading and error widgets

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  addstream_flutter: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Platform Configuration

### Android Setup

Add the following to your `android/app/src/main/AndroidManifest.xml` inside the `<application>` tag:

```xml
<!-- Provide required visibility configuration for API level 30 and above -->
<queries>
    <intent>
        <action android:name="android.support.customtabs.action.CustomTabsService" />
    </intent>
</queries>
```

### iOS Setup

Add the following to your `ios/Runner/Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>https</string>
    <string>http</string>
</array>
```

## Quick Start

### 1. Initialize AddStream

In your `main.dart`, initialize AddStream before running your app:

```dart
import 'package:flutter/material.dart';
import 'package:addstream_flutter/addstream_flutter.dart';

void main() {
  // Initialize AddStream
  AddStreamGlobal.initialize(
    AddStreamConfig(
      apiUrl: 'https://your-api-url.com',
      apiKey: 'your-api-key-here',
    ),
  );
  
  runApp(MyApp());
}
```

### 2. Use the Widget

Add the `AddStreamWidget` anywhere in your app:

```dart
AddStreamWidget(
  zoneId: 'your-zone-id',
  width: 320,
  height: 50,
  margin: const EdgeInsets.all(16),
  borderRadius: 12,
  onAdLoaded: () => print('Ad loaded!'),
  onAdFailed: (error) => print('Error: $error'),
)
```

## Usage Examples

### Basic Banner Ad

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My App')),
      body: Column(
        children: [
          Expanded(
            child: Center(child: Text('Your content here')),
          ),
          // Banner ad at the bottom
          AddStreamWidget(
            zoneId: '123',
            width: 320,
            height: 50,
          ),
        ],
      ),
    );
  }
}
```

### Custom Loading & Error Widgets

```dart
AddStreamWidget(
  zoneId: '123',
  width: 300,
  height: 250,
  loadingWidget: Center(
    child: CircularProgressIndicator(),
  ),
  errorWidget: Container(
    padding: EdgeInsets.all(16),
    child: Text('Ad not available'),
  ),
  onAdLoaded: () {
    print('Ad successfully loaded');
  },
  onAdFailed: (error) {
    print('Failed to load ad: $error');
  },
)
```

### With Callbacks

```dart
AddStreamWidget(
  zoneId: '123',
  width: 320,
  height: 100,
  onAdLoaded: () {
    // Track analytics
    analytics.logEvent('ad_loaded');
  },
  onAdFailed: (error) {
    // Handle error
    if (error is AddStreamException) {
      showErrorDialog(error.message);
    }
  },
)
```

## API Reference

### AddStreamGlobal.initialize()

Initializes the AddStream SDK. Must be called before using any widgets.

**Parameters:**
- `config` (AddStreamConfig): Configuration object

**Example:**
```dart
AddStreamGlobal.initialize(
  AddStreamConfig(
    apiUrl: 'https://your-api-url.com',
    apiKey: 'your-key',
    timeout: Duration(seconds: 10),
  ),
);
```

### AddStreamWidget

Main widget for displaying ads.

**Parameters:**

| Parameter       | Type | Required | Description                               |
|-----------------|------|----------|-------------------------------------------|
| `zoneId`        | String | Yes | Your ad zone ID                           |
| `width`         | double? | No | Ad width (default: 400)                   |
| `height`        | double? | No | Ad height (default: 100)                  |
| `margin`        | EdgeInsetsGeometry? | No | Ad margin (default: null)                 |
| `borderRadius`        | double | No | Ad circular border radius (default: 12.0) |
| `onAdLoaded`    | VoidCallback? | No | Called when ad loads successfully         |
| `onAdFailed`    | Function(Object)? | No | Called when ad fails to load              |
| `loadingWidget` | Widget? | No | Custom loading widget                     |
| `errorWidget`   | Widget? | No | Custom error widget                       |

### AddStreamConfig

Configuration object for initialization.

**Properties:**
- `apiUrl` (String): Base Url
- `apiKey` (String): API key
- `timeout` (Duration): Request timeout (default: 10 seconds)

### AddStreamException

Custom exception class for AddStream errors.

**Properties:**
- `message` (String): Error message
- `originalError` (dynamic): Original error if any

## Error Handling

The package handles errors gracefully and provides multiple ways to handle them:

```dart
// Option 1: Using callback
AddStreamWidget(
  zoneId: '123',
  onAdFailed: (error) {
    if (error is AddStreamException) {
      print('AddStream error: ${error.message}');
    }
  },
)

// Option 2: Try-catch (for initialization)
try {
  AddStreamGlobal.initialize(config);
} on AddStreamException catch (e) {
  print('Failed to initialize: ${e.message}');
}
```

## Common Issues

### Widget not showing

Make sure you've initialized AddStream:
```dart
AddStreamGlobal.initialize(AddStreamConfig(apiUrl: '...', apiKey: '...'));
```

### "AddStream not initialized" error

Call `AddStreamGlobal.initialize()` before using any widgets, typically in your `main()` function.

### No ad appearing

This is normal when there's no ad inventory for your zone. The widget will show the `errorWidget` or hide itself.

## Requirements

- Flutter: >=3.0.0
- Dart: >=3.0.0

## Dependencies

- `http`: ^1.1.0
- `html`: ^0.15.4
- `url_launcher`: ^6.2.0
- `crypto`: ^3.0.6

## License

This package is proprietary software. See [LICENSE](LICENSE) for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.