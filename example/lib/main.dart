import 'package:addstream_flutter/addstream_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  AddStreamGlobal.initialize(
    AddStreamConfig(
      apiKey: 'your-api-key',
      apiUrl: 'https://your-api-url.com',
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'AddStream Example',
      home: _TestScreen(),
    );
  }
}

class _TestScreen extends StatelessWidget {
  const _TestScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AddStream Example')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Banner Ad',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            AddStreamWidget(
              zoneId: 'your-banner-zone-id',
              width: 320,
              height: 50,
              borderRadius: 8,
              margin: const EdgeInsets.symmetric(vertical: 4),
              loadingWidget: const SizedBox(
                height: 50,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              onAdLoaded: () => debugPrint('✅ Banner ad loaded'),
              onAdFailed: (error) => debugPrint('❌ Banner error: $error'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Video Ad',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            AddStreamVideoWidget(
              zoneId: 'your-video-zone-id',
              borderRadius: 8,
              margin: const EdgeInsets.symmetric(vertical: 4),
              loadingWidget: const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              onAdLoaded: () => debugPrint('✅ Video ad loaded'),
              onAdFailed: (error) => debugPrint('❌ Video error: $error'),
              onAdClosed: () => debugPrint('📺 Video ad closed'),
              onTrackingEvent: (event) =>
                  debugPrint('📊 Tracking event: $event'),
            ),
          ],
        ),
      ),
    );
  }
}
