import 'package:flutter/material.dart';

class VideoEndCard extends StatelessWidget {
  final VoidCallback onReplay;
  final VoidCallback onVisitSite;
  final String? clickUrl;
  final double videoHeight;

  const VideoEndCard({
    super.key,
    required this.onReplay,
    required this.onVisitSite,
    this.clickUrl,
    required this.videoHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: videoHeight - 16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Theme(
              data: ThemeData.light().copyWith(
                filledButtonTheme: const FilledButtonThemeData(),
                outlinedButtonTheme: const OutlinedButtonThemeData(),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: onReplay,
                    icon: const Icon(
                      Icons.replay,
                      color: Colors.black,
                    ),
                    label: const Text('Replay'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                    ),
                  ),
                  if (clickUrl != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: onVisitSite,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Visit Site'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
