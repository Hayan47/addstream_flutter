class VASTAd {
  final String id;
  final String adSystem;
  final String adTitle;
  final String description;
  final String impressionUrl;
  final String? clickThroughUrl;
  final VASTCreative creative;

  VASTAd({
    required this.id,
    required this.adSystem,
    required this.adTitle,
    required this.description,
    required this.impressionUrl,
    this.clickThroughUrl,
    required this.creative,
  });
}

class VASTCreative {
  final String id;
  final Duration duration;
  final String videoUrl;
  final Map<String, String> trackingEvents;

  VASTCreative({
    required this.id,
    required this.duration,
    required this.videoUrl,
    required this.trackingEvents,
  });
}

enum VideoAdState {
  uninitialized,
  ready,
  playing,
  paused,
  completed,
  replayed,
}
