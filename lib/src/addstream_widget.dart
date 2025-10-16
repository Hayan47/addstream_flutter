// ============================================
// addstream_widget.dart
// ============================================
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'addstream_service.dart';
import 'dart:developer' as developer;

/// A widget that displays AddStream advertisements.
///
/// This widget fetches and displays ads from the AddStream network based on
/// the provided [zoneId]. It handles loading states, error states, and
/// automatically tracks impressions and clicks.
///
/// Example:
/// ```dart
/// AddStreamWidget(
///   zoneId: 'zone-123',
///   width: 320,
///   height: 50,
///   onAdLoaded: () => print('Ad loaded'),
/// )
/// ```
///
/// See also:
/// * [AddStreamGlobal.initialize], which must be called before using this widget
/// * [AddStreamConfig], for configuring the AddStream SDK
class AddStreamWidget extends StatefulWidget {
  /// The zone ID for the ad placement.
  ///
  /// This ID is provided by AddStream and determines which ads are shown.
  final String zoneId;

  /// The width of the ad widget in logical pixels.
  ///
  /// Defaults to 400 if not specified.
  final double? width;

  /// The height of the ad widget in logical pixels.
  ///
  /// Defaults to 100 if not specified.
  final double? height;

  /// Called when the ad is successfully loaded.
  ///
  /// This callback is useful for tracking ad load success in analytics.
  final VoidCallback? onAdLoaded;

  /// Called when the ad fails to load.
  ///
  /// The [error] parameter contains the error that occurred.
  /// Can be an [AddStreamException] or other error types.
  final Function(Object error)? onAdFailed;

  /// A custom widget to display while the ad is loading.
  ///
  /// If not provided, a default [CircularProgressIndicator] is shown.
  final Widget? loadingWidget;

  /// A custom widget to display when the ad fails to load.
  ///
  /// If not provided, the widget will be hidden using [SizedBox.shrink].
  final Widget? errorWidget;

  /// The margin around the ad widget.
  ///
  /// This is applied outside the ad container and does not affect
  /// the aspect ratio of the ad content.
  final EdgeInsetsGeometry? margin;

  /// The border radius of the ad container in logical pixels.
  ///
  /// Defaults to 12.0 for rounded corners. Set to 0 for square corners.
  final double borderRadius;

  /// Creates an AddStream ad widget.
  ///
  /// The [zoneId] parameter is required and must not be null.

  const AddStreamWidget({
    super.key,
    required this.zoneId,
    this.width,
    this.height,
    this.onAdLoaded,
    this.onAdFailed,
    this.loadingWidget,
    this.errorWidget,
    this.margin,
    this.borderRadius = 8.0,
  });

  @override
  AddStreamWidgetState createState() => AddStreamWidgetState();
}

class AddStreamWidgetState extends State<AddStreamWidget> {
  final AddStreamService _service = AddStreamService();
  AddStreamAd? _ad;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    try {
      final ad = await _service.fetchAd(zoneId: widget.zoneId);

      if (!mounted) return;

      setState(() {
        _ad = ad;
        _isLoading = false;
        _hasError = ad == null;
      });

      if (ad != null) {
        widget.onAdLoaded?.call();
        if (ad.impressionUrl != null) {
          _service.trackImpression(ad.impressionUrl!);
        }
      } else {
        // No ad available - not an error, just no inventory
        widget.onAdFailed?.call('No ad available for zone ${widget.zoneId}');
      }
    } on AddStreamException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      widget.onAdFailed?.call(e.toString());
      // In debug mode, show the error
      assert(() {
        developer.log('❌ AddStream Error: $e');
        return true;
      }());

      rethrow;
    } catch (e) {
      // Handle other unexpected errors
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });

      widget.onAdFailed?.call(e.toString());

      assert(() {
        developer.log('❌ AddStream Unexpected Error: $e');
        return true;
      }());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingWidget ?? SizedBox.shrink();
    }

    if (_hasError || _ad == null) {
      return widget.errorWidget ?? const SizedBox.shrink();
    }

    return _buildImageAd(_ad!);
  }

  Widget _buildImageAd(AddStreamAd ad) {
    return Container(
      margin: widget.margin,
      child: GestureDetector(
        onTap: () => _handleAdClick(ad),
        child: AspectRatio(
          aspectRatio: (widget.width ?? 400) / (widget.height ?? 100),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
                width: 0.2,
              ),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      ad.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        assert(() {
                          developer.log(
                              '⚠️ AddStream: Failed to load ad image: ${ad.imageUrl}');
                          return true;
                        }());
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child:
                                Icon(Icons.error_outline, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                  // Top bar with "Sponsored" label
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      child: const _AnimatedAdBadge(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAdClick(AddStreamAd ad) async {
    if (ad.clickUrl != null && ad.clickUrl!.isNotEmpty) {
      try {
        final uri = Uri.parse(ad.clickUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        assert(() {
          developer.log('⚠️ AddStream: Failed to launch ad URL: $e');
          return true;
        }());
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Animated Ad Badge Widget
class _AnimatedAdBadge extends StatefulWidget {
  const _AnimatedAdBadge();

  @override
  State<_AnimatedAdBadge> createState() => _AnimatedAdBadgeState();
}

class _AnimatedAdBadgeState extends State<_AnimatedAdBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.7), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.02), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _handleAddStreamClick(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logo.png',
                package: 'addstream_flutter',
                width: 14,
                height: 14,
                errorBuilder: (context, error, stackTrace) => SizedBox.shrink(),
              ),
              const SizedBox(width: 3),
              Text(
                'AddStream',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddStreamClick() async {
    try {
      final uri = Uri.parse('https://addstream.net/');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      assert(() {
        developer.log('⚠️ AddStream: Failed to launch ad URL: $e');
        return true;
      }());
    }
  }
}
