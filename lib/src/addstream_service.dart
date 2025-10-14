// ============================================
// addstream_service.dart
// ============================================
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'addstream_config.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:developer' as developer;


class AddStreamException implements Exception {
  final String message;
  final dynamic originalError;

  AddStreamException(this.message, [this.originalError]);

  @override
  String toString() =>
      'AddStreamException: $message${originalError != null ? '\nCaused by: $originalError' : ''}';
}

class AddStreamService {
  String signWithHmac(String key, int timestamp) {
    final message = utf8.encode('timestamp=$timestamp');
    final hmacKey = utf8.encode(key);
    final hmac = Hmac(sha256, hmacKey);
    final digest = hmac.convert(message);
    return digest.toString();
  }

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

      final uri =
          Uri.parse(baseUrl).replace(queryParameters: params);
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
          type: AddStreamAdType.image,
          imageUrl: imageUrl,
          clickUrl: clickUrl,
          impressionUrl: impressionUrl,
          altText: altText,
          width: width,
          height: height,
          zoneId: zoneId,
          rawHtml: htmlContent,
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

  Future<void> trackImpressionAndMarkUsed(
      String adId, String impressionUrl) async {
    await trackImpression(impressionUrl);
  }
}

enum AddStreamAdType { image, text, html }

class AddStreamAd {
  final String id;
  final AddStreamAdType type;
  final String zoneId;
  final String? imageUrl;
  final String? clickUrl;
  final String? impressionUrl;
  final String? altText;
  final String? textContent;
  final int? width;
  final int? height;
  final String rawHtml;

  AddStreamAd({
    required this.id,
    required this.type,
    required this.zoneId,
    this.imageUrl,
    this.clickUrl,
    this.impressionUrl,
    this.altText,
    this.textContent,
    this.width,
    this.height,
    required this.rawHtml,
  });
}
