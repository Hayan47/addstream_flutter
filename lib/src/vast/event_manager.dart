import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../../addstream_flutter.dart';
import 'vast_models.dart';

class EventManager {
  final VASTAd vastAd;
  final Set<String> _firedOneTimeEvents = {};
  bool _impressionFired = false;

  EventManager(this.vastAd);

  Future<void> fireImpression() async {
    if (_impressionFired) return;
    _impressionFired = true;
    try {
      await http.get(Uri.parse(vastAd.impressionUrl)).timeout(
            AddStreamGlobal.config.timeout,
          );
    } catch (e) {
      assert(() {
        developer.log('⚠️ AddStream: Error firing impression: $e',
            name: 'EventManager');
        return true;
      }());
    }
  }

  Future<void> fireEvent(String eventType) async {
    final trackingUrl = vastAd.creative.trackingEvents[eventType];
    if (trackingUrl == null) return;
    try {
      await http
          .get(Uri.parse(trackingUrl))
          .timeout(AddStreamGlobal.config.timeout);
    } catch (e) {
      assert(() {
        developer.log(
            '⚠️ AddStream: Error firing tracking event $eventType: $e',
            name: 'EventManager');
        return true;
      }());
    }
  }

  bool hasEventFired(String eventType) =>
      _firedOneTimeEvents.contains(eventType);

  void markEventFired(String eventType) => _firedOneTimeEvents.add(eventType);

  String? get clickThroughUrl => vastAd.clickThroughUrl;
}
