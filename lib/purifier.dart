import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class PurifierScreen extends StatelessWidget {
  const PurifierScreen({super.key});

  void _openMiHomeApp() async {
    const packageName = 'com.xiaomi.smarthome'; // Xiaomi SmartHome app
    final intent = AndroidIntent(
      action: 'android.intent.action.MAIN',
      package: packageName,
      componentName: 'com.xiaomi.smarthome.SmartHomeMainActivity',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    try {
      await intent.launch();
    } catch (e) {
      debugPrint('❌ Failed to open Mi Home: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purifier'),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF60B574),
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.air, color: Colors.white),
          label: const Text(
            'Open Mi Home App',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0BBEDE),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _openMiHomeApp,
        ),
      ),
    );
  }
}
