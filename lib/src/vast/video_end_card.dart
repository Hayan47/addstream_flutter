import 'package:flutter/material.dart';

class VideoEndCard extends StatelessWidget {
  final VoidCallback onReplay;
  final VoidCallback onVisitSite;
  final String? clickUrl;

  const VideoEndCard({
    super.key,
    required this.onReplay,
    required this.onVisitSite,
    this.clickUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
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
    );
  }
}
