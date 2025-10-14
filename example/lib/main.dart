import 'package:flutter/material.dart';
import 'package:addstream_flutter/addstream_flutter.dart';

void main() {
  // Initialize AddStream
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
    return MaterialApp(
      title: 'AddStream Test',
      home: Scaffold(
        appBar: AppBar(title: const Text('AddStream Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Testing AddStream Widget:'),
              const SizedBox(height: 20),
              AddStreamWidget(
                zoneId: 'zone_123',
                // Your test zone
                width: 320,
                height: 50,
                onAdLoaded: () => print('✅ Ad loaded!'),
                onAdClicked: () => print('👆 Ad clicked!'),
                onAdFailed: (error) => print('❌ Error: $error'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
