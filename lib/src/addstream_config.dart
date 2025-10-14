class AddStreamConfig {
  final String apiUrl;
  final String apiKey;
  final Duration timeout;

  const AddStreamConfig({
    required this.apiUrl,
    required this.apiKey,
    this.timeout = const Duration(seconds: 10),
  });
}



class AddStreamGlobal {
  static AddStreamConfig? _config;

  static void initialize(AddStreamConfig config) {
    _config = config;
  }

  static AddStreamConfig get config {
    if (_config == null) {
      throw Exception('AddStream not initialized. Call AddStreamGlobal.initialize() first.');
    }
    return _config!;
  }

  static bool get isInitialized => _config != null;
}