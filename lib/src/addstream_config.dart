// ============================================
// addstream_config.dart - Add these dartdoc comments
// ============================================

/// Configuration for the AddStream SDK.
///
/// This class holds the configuration settings needed to connect to
/// the AddStream ad network.
///
/// Example:
/// ```dart
/// final config = AddStreamConfig(
///   apiUrl: 'https://your-api-url.com',
///   apiKey: 'your-api-key',
///   timeout: Duration(seconds: 10),
/// );
/// ```
class AddStreamConfig {
  /// The base URL for the AddStream API.
  ///
  /// This should typically be 'https://your-api-url.com' for production.
  final String apiUrl;

  /// The API key for authentication (optional).
  ///
  /// If provided, this will be sent as a Bearer token in API requests.
  final String apiKey;

  /// The timeout duration for API requests.
  ///
  /// Defaults to 10 seconds if not specified.
  final Duration timeout;

  /// Creates an AddStream configuration.
  ///
  /// The [apiUrl] parameter is required and must not be empty.
  const AddStreamConfig({
    required this.apiUrl,
    required this.apiKey,
    this.timeout = const Duration(seconds: 10),
  });
}

// Global singleton for AddStream SDK initialization.
///
/// This class manages the global configuration for the AddStream SDK.
/// You must call [initialize] before using any AddStream widgets.
///
/// Example:
/// ```dart
/// void main() {
///   AddStreamGlobal.initialize(
///     AddStreamConfig(
///       apiUrl: 'https://your-api-url.com',
///       apiKey: 'your-key',
///     ),
///   );
///   runApp(MyApp());
/// }
/// ```
class AddStreamGlobal {
  static AddStreamConfig? _config;

  /// Initializes the AddStream SDK with the provided configuration.
  ///
  /// This method must be called once before using any [AddStreamWidget].
  /// Typically called in the `main()` function before `runApp()`.
  ///
  /// Throws an [Exception] if called multiple times.
  static void initialize(AddStreamConfig config) {
    _config = config;
  }

  /// Returns the current AddStream configuration.
  ///
  /// Throws an [Exception] if [initialize] has not been called yet.
  static AddStreamConfig get config {
    if (_config == null) {
      throw Exception(
          'AddStream not initialized. Call AddStreamGlobal.initialize() first.');
    }
    return _config!;
  }

  /// Returns `true` if the AddStream SDK has been initialized.
  static bool get isInitialized => _config != null;
}
