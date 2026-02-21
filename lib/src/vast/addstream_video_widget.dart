import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:audio_session/audio_session.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../addstream_config.dart';
import '../addstream_service.dart';
import '../shared/animated_ad_badge.dart';
import 'event_manager.dart';
import 'fullscreen_video_player.dart';
import 'vast_models.dart';
import 'vast_parser.dart';
import 'video_end_card.dart';
import 'video_icon_button.dart';
import 'video_state_manager.dart';

/// A widget that displays a VAST video advertisement.
///
/// Fetches a VAST XML response from the AddStream network and plays the
/// video creative, firing all standard IAB tracking events automatically.
///
/// Requires [AddStreamGlobal.initialize] to be called before use.
///
/// Example:
/// ```dart
/// AddStreamVideoWidget(
///   zoneId: 'your-zone-id',
///   autoPlay: true,
///   onAdClosed: () => print('Ad closed'),
/// )
/// ```
class AddStreamVideoWidget extends StatefulWidget {
  /// The zone ID for the video ad placement.
  ///
  /// Provided by AddStream and determines which video ad is served.
  final String zoneId;

  /// Called when the video ad is successfully loaded and ready to play.
  final VoidCallback? onAdLoaded;

  /// Called when the first video frame is actually rendered on screen.
  ///
  /// Unlike [onAdLoaded] which fires after initialization, this fires once
  /// the video player has decoded and presented the first visible frame.
  final VoidCallback? onVideoReady;

  /// Called when the video ad fails to load or initialize.
  ///
  /// The [error] parameter contains the error that occurred.
  /// Can be an [AddStreamException] or other error types.
  final Function(Object error)? onAdFailed;

  /// Called when the user dismisses the video ad via the close button.
  final VoidCallback? onAdClosed;

  /// Called whenever an IAB VAST tracking event fires.
  ///
  /// The [eventType] parameter is one of: `start`, `firstQuartile`,
  /// `midpoint`, `thirdQuartile`, `complete`, `pause`, `resume`,
  /// `mute`, `unmute`, `fullscreen`, `click`, `stop`, `replay`.
  final Function(String eventType)? onTrackingEvent;

  /// A custom widget to display while the video ad is loading.
  ///
  /// If not provided, the widget is hidden using [SizedBox.shrink].
  final Widget? loadingWidget;

  /// A custom widget to display when the video ad fails to load.
  ///
  /// If not provided, the widget is hidden using [SizedBox.shrink].
  final Widget? errorWidget;

  /// The margin around the video ad widget.
  final EdgeInsetsGeometry? margin;

  /// The border radius of the video ad container in logical pixels.
  ///
  /// Defaults to 8.0. Set to 0 for square corners.
  final double borderRadius;

  /// Creates an AddStream video ad widget.
  ///
  /// The [zoneId] parameter is required. Ensure [AddStreamGlobal.initialize]
  /// has been called with a valid [videoApiUrl] before using this widget.
  const AddStreamVideoWidget({
    super.key,
    required this.zoneId,
    this.onAdLoaded,
    this.onVideoReady,
    this.onAdFailed,
    this.onAdClosed,
    this.onTrackingEvent,
    this.loadingWidget,
    this.errorWidget,
    this.margin,
    this.borderRadius = 8.0,
  });

  @override
  State<AddStreamVideoWidget> createState() => _AddStreamVideoWidgetState();
}

class _AddStreamVideoWidgetState extends State<AddStreamVideoWidget> {
  late final Future<void> _initializationFuture;
  late final VideoStateManager _stateManager = VideoStateManager();

  VideoPlayerController? _videoController;
  EventManager? _eventManager;
  Timer? _progressTimer;
  bool _isClosed = false;
  bool _isCompleted = false;
  bool _videoReadyFired = false;
  bool _videoVisible = false;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeWidget();
  }

  Future<void> _initializeWidget() async {
    final config = AddStreamGlobal.config;

    try {
      final uri = Uri.parse(config.videoApiUrl!).replace(queryParameters: {
        'script': 'apVideo:vast2',
        'zoneid': widget.zoneId,
      });

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _signWithHmac(config.apiKey, timestamp);

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'AddStream-Flutter-SDK/1.0',
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      ).timeout(config.timeout);

      if (response.statusCode != 200) {
        throw AddStreamException(
            'Failed to load Video: ${response.statusCode}');
      }

      final vastAd = VASTParser.parseVAST(response.body);
      if (vastAd == null) throw AddStreamException('Failed to parse Video');

      _eventManager = EventManager(vastAd);
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(vastAd.creative.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await _videoController!.initialize();
      _stateManager.updateState(VideoAdState.ready);

      _videoController!.addListener(_handleVideoStateChanges);
      _videoController!.addListener(_checkFirstFrame);

      _videoController!.setVolume(0);
      await _configureAudioSession(muted: true);
      await _videoController!.play();
      _stateManager.updateState(VideoAdState.playing);

      await _eventManager!.fireImpression();
      widget.onAdLoaded?.call();
    } on AddStreamException catch (e) {
      assert(() {
        developer.log('❌ AddStream Error: $e');
        return true;
      }());
      widget.onAdFailed?.call(e);
    } catch (e) {
      assert(() {
        developer.log('❌ AddStream Error: $e');
        return true;
      }());
      widget.onAdFailed?.call(e);
    }
  }

  String _signWithHmac(String key, int timestamp) {
    final message = utf8.encode('timestamp=$timestamp');
    final hmacKey = utf8.encode(key);
    final hmac = Hmac(sha256, hmacKey);
    return hmac.convert(message).toString();
  }

  Future<void> _configureAudioSession({required bool muted}) async {
    final session = await AudioSession.instance;
    if (muted) {
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.movie,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: true,
      ));
    } else {
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.movie,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ));
      await session.setActive(true);
    }
  }

  void _handleVideoStateChanges() {
    final controller = _videoController;
    if (controller == null) return;

    final value = controller.value;
    final position = value.position;
    final duration = value.duration;

    // ready → playing (start)
    if (value.isPlaying && _stateManager.isInState(VideoAdState.ready)) {
      _stateManager.updateState(VideoAdState.playing);
      _eventManager!.markEventFired('start');
      _eventManager!.fireEvent('start');
      _startProgressTracking();
      widget.onTrackingEvent?.call('start');
    }

    // playing/replayed → paused
    if (!value.isPlaying &&
        (_stateManager.isInState(VideoAdState.playing) ||
            _stateManager.isInState(VideoAdState.replayed)) &&
        position < duration) {
      _stateManager.updateState(VideoAdState.paused);
      _stopProgressTracking();
      if (!_eventManager!.hasEventFired('pause')) {
        _eventManager!.markEventFired('pause');
        _eventManager!.fireEvent('pause');
        widget.onTrackingEvent?.call('pause');
      }
    }

    // paused → playing (resume)
    if (value.isPlaying && _stateManager.isInState(VideoAdState.paused)) {
      _stateManager.updateState(VideoAdState.playing);
      _startProgressTracking();
      if (!_eventManager!.hasEventFired('resume')) {
        _eventManager!.markEventFired('resume');
        _eventManager!.fireEvent('resume');
        widget.onTrackingEvent?.call('resume');
      }
    }

    // → completed
    if (position >= duration && duration > Duration.zero && !value.isPlaying) {
      if (!(_stateManager.isInState(VideoAdState.completed) ||
          _stateManager.isInState(VideoAdState.replayed))) {
        _stateManager.updateState(VideoAdState.completed);
        _stopProgressTracking();
        _eventManager!.markEventFired('complete');
        _eventManager!.fireEvent('complete');
        widget.onTrackingEvent?.call('complete');
        if (mounted) setState(() => _isCompleted = true);
      }
    }

    // completed → replayed
    if (value.isPlaying && _stateManager.isInState(VideoAdState.completed)) {
      _stateManager.updateState(VideoAdState.replayed);
      _eventManager!.markEventFired('replay');
      _eventManager!.fireEvent('replay');
      widget.onTrackingEvent?.call('replay');
    }
  }

  void _startProgressTracking() {
    if (_progressTimer != null) return;
    _progressTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      final controller = _videoController;
      if (controller == null || !controller.value.isPlaying) {
        _stopProgressTracking();
        return;
      }

      final position = controller.value.position;
      final duration = controller.value.duration;
      if (duration.inMilliseconds == 0) return;

      final progress = position.inMilliseconds / duration.inMilliseconds;

      if (progress >= 0.25 && !_eventManager!.hasEventFired('firstQuartile')) {
        _eventManager!.markEventFired('firstQuartile');
        _eventManager!.fireEvent('firstQuartile');
        widget.onTrackingEvent?.call('firstQuartile');
      }
      if (progress >= 0.50 && !_eventManager!.hasEventFired('midpoint')) {
        _eventManager!.markEventFired('midpoint');
        _eventManager!.fireEvent('midpoint');
        widget.onTrackingEvent?.call('midpoint');
      }
      if (progress >= 0.75 && !_eventManager!.hasEventFired('thirdQuartile')) {
        _eventManager!.markEventFired('thirdQuartile');
        _eventManager!.fireEvent('thirdQuartile');
        widget.onTrackingEvent?.call('thirdQuartile');
      }
    });
  }

  void _stopProgressTracking() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  void _replayVideo() {
    _videoController?.play();
    setState(() => _isCompleted = false);
  }

  void _toggleVolume() {
    final controller = _videoController;
    if (controller == null) return;
    final isMuted = controller.value.volume == 0;
    if (isMuted) {
      controller.setVolume(1);
      _configureAudioSession(muted: false);
      if (!_eventManager!.hasEventFired('unmute')) {
        _eventManager!.markEventFired('unmute');
        _eventManager!.fireEvent('unmute');
        widget.onTrackingEvent?.call('unmute');
      }
    } else {
      controller.setVolume(0);
      _configureAudioSession(muted: true);
      if (!_eventManager!.hasEventFired('mute')) {
        _eventManager!.markEventFired('mute');
        _eventManager!.fireEvent('mute');
        widget.onTrackingEvent?.call('mute');
      }
    }
  }

  void _togglePlayPause() {
    final controller = _videoController;
    if (controller == null) return;
    controller.value.isPlaying ? controller.pause() : controller.play();
  }

  Future<void> _handleAdClick() async {
    final clickUrl = _eventManager?.clickThroughUrl;
    if (clickUrl == null) return;
    widget.onTrackingEvent?.call('click');
    final uri = Uri.parse(clickUrl);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _enterFullscreen() async {
    final controller = _videoController;
    if (controller == null) return;
    if (!_eventManager!.hasEventFired('fullscreen')) {
      _eventManager!.markEventFired('fullscreen');
      _eventManager!.fireEvent('fullscreen');
      widget.onTrackingEvent?.call('fullscreen');
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenVideoPlayer(
          videoController: controller,
          onToggleVolume: _toggleVolume,
          onTogglePlayPause: _togglePlayPause,
          heroTag: 'addstream_video_${widget.zoneId}',
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _closeAd() {
    final controller = _videoController;
    if (controller != null) {
      widget.onAdClosed?.call();
      if (!(_stateManager.isInState(VideoAdState.completed) ||
          _stateManager.isInState(VideoAdState.uninitialized))) {
        _eventManager?.fireEvent('stop');
        widget.onTrackingEvent?.call('stop');
      }
      controller.removeListener(_handleVideoStateChanges);
      controller.dispose();
      _videoController = null;
    }
    setState(() => _isClosed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!AddStreamGlobal.isInitialized) {
      throw AddStreamException(
        'AddStreamGlobal.initialize() must be called before using AddStreamVideoWidget.',
      );
    }
    if (AddStreamGlobal.config.videoApiUrl == null) {
      throw AddStreamException(
        'videoApiUrl is not set in AddStreamConfig. Provide it to use AddStreamVideoWidget.',
      );
    }

    if (_isClosed) return const SizedBox.shrink();

    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.loadingWidget ?? const SizedBox.shrink();
        }

        if (snapshot.hasError ||
            _videoController?.value.isInitialized != true) {
          return widget.errorWidget ?? const SizedBox.shrink();
        }

        return AnimatedSize(
          duration: const Duration(milliseconds: 750),
          curve: Curves.easeOut,
          child: !_videoVisible
              ? widget.loadingWidget ?? const SizedBox.shrink()
              : Container(
                  margin: widget.margin,
                  child: GestureDetector(
                    onTap: _handleAdClick,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final aspectRatio = _videoController!.value.aspectRatio;
                        final height = (constraints.maxWidth / aspectRatio)
                            .clamp(100.0, 400.0);
                        final videoWidth = height * aspectRatio;
                        return Center(
                          child: SizedBox(
                            height: height,
                            width: videoWidth,
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(widget.borderRadius),
                              child: Stack(
                                children: [
                                  Hero(
                                    tag: 'addstream_video_${widget.zoneId}',
                                    child: VideoPlayer(_videoController!),
                                  ),
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const AnimatedAdBadge(),
                                          const Spacer(),
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxHeight: height - 16,
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.topCenter,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  VideoIconButton(
                                                    icon: Icons.close,
                                                    onPressed: _closeAd,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  ValueListenableBuilder<
                                                      VideoPlayerValue>(
                                                    valueListenable:
                                                        _videoController!,
                                                    builder: (_, value, __) =>
                                                        VideoIconButton(
                                                      icon: value.isPlaying
                                                          ? Icons.pause
                                                          : Icons.play_arrow,
                                                      onPressed:
                                                          _togglePlayPause,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  VideoIconButton(
                                                    icon: Icons.fullscreen,
                                                    onPressed: _enterFullscreen,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  ValueListenableBuilder<
                                                      VideoPlayerValue>(
                                                    valueListenable:
                                                        _videoController!,
                                                    builder: (_, value, __) =>
                                                        VideoIconButton(
                                                      icon: value.volume == 0
                                                          ? Icons.volume_off
                                                          : Icons.volume_up,
                                                      onPressed: _toggleVolume,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: VideoProgressIndicator(
                                      _videoController!,
                                      allowScrubbing: false,
                                      colors: const VideoProgressColors(
                                        playedColor: Colors.red,
                                        backgroundColor: Colors.white24,
                                        bufferedColor: Colors.white38,
                                      ),
                                    ),
                                  ),
                                  if (_isCompleted)
                                    VideoEndCard(
                                      onReplay: _replayVideo,
                                      onVisitSite: _handleAdClick,
                                      clickUrl: _eventManager?.clickThroughUrl,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        );
      },
    );
  }

  void _checkFirstFrame() {
    final controller = _videoController;
    if (controller == null || _videoReadyFired) return;
    if (controller.value.isInitialized &&
        controller.value.position > Duration(milliseconds: 1500)) {
      _videoReadyFired = true;
      controller.removeListener(_checkFirstFrame);
      setState(() => _videoVisible = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onVideoReady?.call();
      });
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    final controller = _videoController;
    if (controller != null) {
      if (!(_stateManager.isInState(VideoAdState.completed) ||
          _stateManager.isInState(VideoAdState.uninitialized))) {
        _eventManager?.fireEvent('stop');
        widget.onTrackingEvent?.call('stop');
      }
      controller.removeListener(_checkFirstFrame);
      controller.removeListener(_handleVideoStateChanges);
      controller.dispose();
    }
    super.dispose();
  }
}
