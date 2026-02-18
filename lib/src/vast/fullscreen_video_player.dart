import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'video_icon_button.dart';

class FullscreenVideoPlayer extends StatelessWidget {
  final VideoPlayerController videoController;
  final VoidCallback onToggleVolume;
  final VoidCallback onTogglePlayPause;

  const FullscreenVideoPlayer({
    super.key,
    required this.videoController,
    required this.onToggleVolume,
    required this.onTogglePlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: videoController.value.aspectRatio,
                child: VideoPlayer(videoController),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: VideoIconButton(
                icon: Icons.close,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: Row(
                children: [
                  ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: videoController,
                    builder: (_, value, __) => VideoIconButton(
                      icon: value.volume == 0
                          ? Icons.volume_off
                          : Icons.volume_up,
                      onPressed: onToggleVolume,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: videoController,
                    builder: (_, value, __) => VideoIconButton(
                      icon: value.isPlaying ? Icons.pause : Icons.play_arrow,
                      onPressed: onTogglePlayPause,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
