import 'package:xml/xml.dart';

import 'vast_models.dart';

class VASTParser {
  static VASTAd? parseVAST(String xmlContent) {
    try {
      final document = XmlDocument.parse(xmlContent);
      final adElement =
          document.findElements('VAST').first.findElements('Ad').first;
      final inlineElement = adElement.findElements('InLine').first;

      final adId = adElement.getAttribute('id') ?? '';
      final adSystem =
          inlineElement.findElements('AdSystem').first.innerText.trim();
      final adTitle =
          inlineElement.findElements('AdTitle').first.innerText.trim();
      final description =
          inlineElement.findElements('Description').first.innerText.trim();
      final impressionUrl =
          inlineElement.findElements('Impression').first.innerText.trim();

      final creativeElement = inlineElement
          .findElements('Creatives')
          .first
          .findElements('Creative')
          .first;
      final linearElement = creativeElement.findElements('Linear').first;
      final creativeId = creativeElement.getAttribute('id') ?? '';

      final duration = _parseDuration(
        linearElement.findElements('Duration').first.innerText.trim(),
      );

      final videoUrl = linearElement
          .findElements('MediaFiles')
          .first
          .findElements('MediaFile')
          .first
          .innerText
          .trim();

      final clickThroughUrl = linearElement
          .findElements('VideoClicks')
          .first
          .findElements('ClickThrough')
          .first
          .innerText
          .trim();

      final trackingEvents = <String, String>{};
      for (final element in linearElement
          .findElements('TrackingEvents')
          .first
          .findElements('Tracking')) {
        final event = element.getAttribute('event') ?? '';
        trackingEvents[event] = element.innerText.trim();
      }

      return VASTAd(
        id: adId,
        adSystem: adSystem,
        adTitle: adTitle,
        description: description,
        impressionUrl: impressionUrl,
        clickThroughUrl: clickThroughUrl,
        creative: VASTCreative(
          id: creativeId,
          duration: duration,
          videoUrl: videoUrl,
          trackingEvents: trackingEvents,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  static Duration _parseDuration(String durationStr) {
    final parts = durationStr.split(':');
    if (parts.length == 3) {
      return Duration(
        hours: int.tryParse(parts[0]) ?? 0,
        minutes: int.tryParse(parts[1]) ?? 0,
        seconds: int.tryParse(parts[2]) ?? 0,
      );
    }
    return Duration.zero;
  }
}
