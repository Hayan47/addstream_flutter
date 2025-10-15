// lib/addstream_flutter.dart

/// AddStream Flutter SDK for displaying advertisements.
///
/// This library provides widgets and services for integrating AddStream ads
/// into Flutter applications.
///
/// To use this library:
/// 1. Initialize the SDK in your main function
/// 2. Use AddStreamWidget to display ads
///
/// Example:
/// ```dart
/// import 'package:addstream_flutter/addstream_flutter.dart';
///
/// void main() {
///   AddStreamGlobal.initialize(
///     AddStreamConfig(apiUrl: 'https://your-api-url.com'),
///   );
///   runApp(MyApp());
/// }
/// ```
library addstream_flutter;

export 'src/addstream_widget.dart';
export 'src/addstream_config.dart';
export 'src/addstream_service.dart';
