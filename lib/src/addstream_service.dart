// ============================================
// addstream_service.dart
// ============================================
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

import 'addstream_config.dart';

/// Custom exception for AddStream-specific errors.
///
/// This exception is thrown when operations in the AddStream SDK fail.
/// It includes a descriptive message and optionally wraps the original error.
class AddStreamException implements Exception {
  /// The error message describing what went wrong.
  final String message;

  /// The original error that caused this exception, if any.
  final dynamic originalError;

  /// Creates an AddStream exception with the given [message].
  ///
  /// Optionally includes the [originalError] that caused this exception.
  AddStreamException(this.message, [this.originalError]);

  @override
  String toString() =>
      'AddStreamException: $message${originalError != null ? '\nCaused by: $originalError' : ''}';
}

/// Service class for fetching and tracking ads from AddStream.
///
/// This class handles communication with the AddStream API, including
/// fetching ads, parsing responses, and tracking impressions.
///
/// You typically don't need to use this class directly. The [AddStreamWidget]
/// uses it internally.
class AddStreamService {
  /// Generates an HMAC-SHA256 signature for the given [key] and [timestamp].
  ///
  /// Used internally to authenticate requests to the AddStream API.
  String signWithHmac(String key, int timestamp) {
    final message = utf8.encode('timestamp=$timestamp');
    final hmacKey = utf8.encode(key);
    final hmac = Hmac(sha256, hmacKey);
    final digest = hmac.convert(message);
    return digest.toString();
  }

  /// Fetches an ad for the specified [zoneId].
  ///
  /// Returns an [AddStreamAd] if successful, or `null` if no ad is available.
  /// Throws [AddStreamException] if the request fails or if the SDK is not initialized.
  ///
  /// The [zoneId] parameter specifies which ad zone to fetch from.
  Future<AddStreamAd?> fetchAd({required String zoneId}) async {
    if (!AddStreamGlobal.isInitialized) {
      throw AddStreamException(
        'AddStream not initialized. Call AddStreamGlobal.initialize() before using AddStreamWidget.',
      );
    }

    try {
      final config = AddStreamGlobal.config;

      final String baseUrl = config.apiUrl;

      final random = Random().nextInt(999999999);

      final params = <String, dynamic>{
        'zoneid': zoneId,
        'cb': random.toString(),
        'loc': 'app://flutter-app',
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: params);
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = signWithHmac(
        config.apiKey,
        timestamp,
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'AddStream-Flutter-SDK/1.0',
          'Accept': 'application/javascript, text/javascript, */*',
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      ).timeout(config.timeout);

      if (response.statusCode == 200) {
        return _parseAdResponse(response.body, zoneId);
      } else if (response.statusCode == 404) {
        // Zone not found - return null (no ad available)
        return null;
      } else if (response.statusCode >= 500) {
        throw AddStreamException(
          'Server error (${response.statusCode}). Please try again later.',
        );
      } else {
        throw AddStreamException(
          'Failed to fetch ad. HTTP ${response.statusCode}',
        );
      }
    } on AddStreamException {
      rethrow;
    } catch (e) {
      throw AddStreamException('Network error while fetching ad', e);
    }
  }

  AddStreamAd? _parseAdResponse(String jsResponse, String zoneId) {
    try {
      String htmlContent = jsResponse;

      if (htmlContent.isEmpty) return null;

      htmlContent = htmlContent
          .replaceAll('<"+"/', '</')
          .replaceAll('<"+"', '<')
          .replaceAll(r"\'", "'")
          .replaceAll(r'\"', '"')
          .replaceAll('&amp;', '&');

      final doc = parse(htmlContent);

      final clickAnchor = doc.querySelector("a[href*='cl.php']");
      final clickUrl = clickAnchor?.attributes['href'];

      final adImageElement = doc.querySelector('img:not([src*="lg.php"])');
      final imageUrl = adImageElement?.attributes['src'];

      final impressionImg = doc.querySelector("img[src*='lg.php']");
      final impressionUrl = impressionImg?.attributes['src'];

      final width = int.tryParse(adImageElement?.attributes['width'] ?? '');
      final height = int.tryParse(adImageElement?.attributes['height'] ?? '');
      final altText = adImageElement?.attributes['alt'] ?? '';

      if (imageUrl != null && imageUrl.isNotEmpty) {
        return AddStreamAd(
          id: _generateAdId(zoneId, imageUrl),
          imageUrl: imageUrl,
          clickUrl: clickUrl,
          impressionUrl: impressionUrl,
          altText: altText,
          width: width,
          height: height,
          zoneId: zoneId,
        );
      }

      return null;
    } catch (e) {
      throw AddStreamException('Failed to parse ad response', e);
    }
  }

  String _generateAdId(String zoneId, String content) {
    return '$zoneId-${content.hashCode}';
  }

  /// Tracks an impression for the given ad.
  ///
  /// This method is called automatically when an ad is displayed.
  /// Failures are logged but do not throw exceptions.
  ///
  /// The [impressionUrl] is provided by the ad server in the ad response.
  Future<void> trackImpression(String impressionUrl) async {
    try {
      await http.get(Uri.parse(impressionUrl));
    } catch (e) {
      // Silently fail for impression tracking - don't throw
      // Impression tracking failures shouldn't break the app
      assert(() {
        developer.log('⚠️ AddStream: Failed to track impression: $e');
        return true;
      }());
    }
  }
}

class AddStreamAd {
  /// Unique identifier for this ad.
  final String id;

  /// The zone ID this ad was fetched from.
  final String zoneId;

  /// The URL of the ad image (for image ads).
  final String? imageUrl;

  /// The URL to open when the ad is clicked.
  final String? clickUrl;

  /// The URL to call for impression tracking.
  final String? impressionUrl;

  /// Alternative text for the ad image.
  final String? altText;

  /// Width of the ad creative in pixels.
  final int? width;

  /// Height of the ad creative in pixels.
  final int? height;

  /// Creates an AddStream ad.
  ///
  /// The [id], and [zoneId] parameters are required.
  AddStreamAd({
    required this.id,
    required this.zoneId,
    this.imageUrl,
    this.clickUrl,
    this.impressionUrl,
    this.altText,
    this.width,
    this.height,
  });
}
