import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../shared/animated_ad_badge.dart';

class FullscreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController videoController;
  final VoidCallback onToggleVolume;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onReplay;
  final String heroTag;
  final VoidCallback onVisitSite;
  final String? clickUrl;

  const FullscreenVideoPlayer({
    super.key,
    required this.videoController,
    required this.onToggleVolume,
    required this.onTogglePlayPause,
    required this.onReplay,
    required this.heroTag,
    required this.onVisitSite,
    required this.clickUrl,
  });

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // 2D drag
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  void _onTap() {
    if (_fadeController.value < 0.5) {
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    const dismissDistance = 100.0;
    const dismissVelocity = 800.0;

    final distance = _dragOffset.distance;
    final velocity = details.velocity.pixelsPerSecond.distance;

    if (distance > dismissDistance || velocity > dismissVelocity) {
      Navigator.of(context).pop(true);
    } else {
      // Snap back with spring feel
      setState(() {
        _dragOffset = Offset.zero;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Normalize drag distance for visual feedback (0.0 → 1.0)
    final dragProgress = (_dragOffset.distance / 300).clamp(0.0, 1.0);
    final bgOpacity = (1.0 - dragProgress).clamp(0.0, 1.0);
    final scale = (1.0 - dragProgress * 0.10).clamp(0.90, 1.0);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(bgOpacity),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Transform.translate(
          offset: _dragOffset,
          child: Transform.scale(
            scale: scale,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Video ─────────────────────────────────────
                Center(
                  child: AspectRatio(
                    aspectRatio: widget.videoController.value.aspectRatio,
                    child: Hero(
                      tag: widget.heroTag,
                      child: VideoPlayer(widget.videoController),
                    ),
                  ),
                ),

                // ── Top: Ad badge ──────────────────────────────
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AnimatedAdBadge(),
                              const SizedBox(width: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Bottom: progress + controls ────────────────
                Align(
                  alignment: Alignment.bottomCenter,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.85),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Progress
                              ValueListenableBuilder<VideoPlayerValue>(
                                valueListenable: widget.videoController,
                                builder: (_, value, __) {
                                  final total =
                                      value.duration.inMilliseconds.toDouble();
                                  final pos =
                                      value.position.inMilliseconds.toDouble();
                                  final progress = total > 0
                                      ? (pos / total).clamp(0.0, 1.0)
                                      : 0.0;
                                  return Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_formatDuration(value.position),
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11)),
                                          Text(_formatDuration(value.duration),
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor:
                                              Colors.white.withOpacity(0.25),
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                  Colors.white),
                                          minHeight: 3,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              // Controls
                              Row(
                                children: [
                                  ValueListenableBuilder<VideoPlayerValue>(
                                    valueListenable: widget.videoController,
                                    builder: (_, value, __) {
                                      final isFinished =
                                          value.duration > Duration.zero &&
                                              value.position >= value.duration;

                                      return _GlassIconButton(
                                        icon: isFinished
                                            ? Icons.replay_rounded
                                            : value.isPlaying
                                                ? Icons.pause_rounded
                                                : Icons.play_arrow_rounded,
                                        onPressed: isFinished
                                            ? widget.onReplay
                                            : widget.onTogglePlayPause,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  ValueListenableBuilder<VideoPlayerValue>(
                                    valueListenable: widget.videoController,
                                    builder: (_, value, __) => _GlassIconButton(
                                      icon: value.volume == 0
                                          ? Icons.volume_off_rounded
                                          : Icons.volume_up_rounded,
                                      onPressed: widget.onToggleVolume,
                                    ),
                                  ),
                                  Spacer(),
                                  // ── CTA Button ──────────────────────────────────
                                  if (widget.clickUrl != null) ...[
                                    Theme(
                                      data: ThemeData.light().copyWith(
                                        outlinedButtonTheme:
                                            const OutlinedButtonThemeData(),
                                      ),
                                      child: OutlinedButton.icon(
                                        onPressed: widget.onVisitSite,
                                        icon: const Icon(Icons.open_in_new),
                                        label: const Text('Visit Site'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: const BorderSide(
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],

                                  _GlassIconButton(
                                    icon: Icons.close_rounded,
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          // More opaque than before — this fixes the visibility issue
          color: Colors.white.withOpacity(0.22),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
