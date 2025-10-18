import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:telephony/telephony.dart';
import 'history.dart';

class ConditionScreen extends StatefulWidget {
  final Function(double, double) onSensorDataChanged;

  const ConditionScreen({required this.onSensorDataChanged, Key? key})
    : super(key: key);

  @override
  _ConditionScreenState createState() => _ConditionScreenState();
}

class _ConditionScreenState extends State<ConditionScreen> {
  double ammoniaLevel = 0.0;
  double co2Level = 0.0;
  Timer? timer;
  bool _alertShowing = false;
  bool _smsSent = false;

  String? _lastNH3Rec;
  String? _lastCO2Rec;

  final String espIPco2 = 'http://192.168.1.20';
  final String espIPammonia = 'http://192.168.1.19';

  final Telephony telephony = Telephony.instance;
  final String phoneNumber = "639086504117"; // target number

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    _startFetching();
  }

  Future<void> _initializeDatabase() async {
    try {
      await DatabaseHelper().database;
      print("✅ Database initialized successfully");
    } catch (e) {
      print("❌ Database initialization failed: $e");
    }
  }

  void _startFetching() {
    _fetchAndStoreData();
    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchAndStoreData();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // Simplified (ASCII-safe) recommendation texts
  String getNH3Recommendation(double nh3) {
    if (nh3 <= 10) return "NH3: 0-10 ppm - Optimal";
    if (nh3 <= 25) return "NH3: 11-25 ppm - Moderate";
    return "NH3: >25 ppm - High";
  }

  String getCO2Recommendation(double co2) {
    if (co2 <= 2000) return "CO2: 0-2000 ppm - Optimal";
    if (co2 <= 3000) return "CO2: 2001-3000 ppm - Moderate";
    return "CO2: >3000 ppm - High";
  }

  Future<void> _sendSmsIfNeeded() async {
    String nh3Rec = getNH3Recommendation(ammoniaLevel);
    String co2Rec = getCO2Recommendation(co2Level);

    // Send SMS if first time or recommendation changed
    if (!_smsSent || _lastNH3Rec != nh3Rec || _lastCO2Rec != co2Rec) {
      String message =
          "Current Air Quality:\n$co2Rec\n$nh3Rec\nCO2: ${co2Level.toStringAsFixed(0)} ppm, NH3: ${ammoniaLevel.toStringAsFixed(1)} ppm";

      try {
        bool? permissionsGranted =
            await telephony.requestPhoneAndSmsPermissions;
        if (permissionsGranted ?? false) {
          await telephony.sendSms(to: phoneNumber, message: message);
          print("📩 SMS sent: $message");
          _smsSent = true;
          _lastNH3Rec = nh3Rec;
          _lastCO2Rec = co2Rec;
        } else {
          print("❌ SMS permissions not granted");
        }
      } catch (e) {
        print("❌ Failed to send SMS: $e");
      }
    }
  }

  Future<void> _fetchAndStoreData() async {
    try {
      // Fetch CO2
      final co2Response = await http.get(Uri.parse('$espIPco2/readings'));
      if (co2Response.statusCode == 200) {
        final co2Data = jsonDecode(co2Response.body);
        co2Level = (co2Data['co2'] ?? 0).toDouble();
      }

      // Fetch Ammonia
      final nh3Response = await http.get(Uri.parse('$espIPammonia/readings'));
      if (nh3Response.statusCode == 200) {
        final nh3Data = jsonDecode(nh3Response.body);
        ammoniaLevel = (nh3Data['ammonia'] ?? 0).toDouble();
      }

      if (!mounted) return;
      setState(() {});

      widget.onSensorDataChanged(co2Level, ammoniaLevel);

      await DatabaseHelper().insertReading(
        DateTime.now().toIso8601String(),
        co2Level,
        ammoniaLevel,
      );

      print("💾 Inserted CO2: $co2Level ppm, NH3: $ammoniaLevel ppm");

      _checkAlerts(co2Level, ammoniaLevel);

      // Send SMS if needed (plain text only)
      await _sendSmsIfNeeded();
    } catch (e) {
      print("❌ Fetch/store error: $e");
    }
  }

  void _checkAlerts(double co2, double nh3) {
    if (co2 > 3000) {
      _showAlert('High CO2 Level', 'CO2 is above 3000 ppm!');
    } else if (co2 > 2000) {
      _showAlert('Moderate CO2 Level', 'CO2 is 2001-3000 ppm');
    }

    if (nh3 > 25) {
      _showAlert('High Ammonia Level', 'Ammonia is above 25 ppm!');
    } else if (nh3 > 10) {
      _showAlert('Moderate Ammonia Level', 'Ammonia is 11-25 ppm');
    }
  }

  void _showAlert(String title, String message) {
    if (_alertShowing) return;
    _alertShowing = true;
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              title,
              style: const TextStyle(color: Color(0xFF60B574)),
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  _alertShowing = false;
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'OK',
                  style: TextStyle(color: Color(0xFF60B574)),
                ),
              ),
            ],
          ),
    );
  }

  double _normalizeCO2(double ppm) => (ppm.clamp(0, 4000) / 4000);
  double _normalizeAmmonia(double ppm) => (ppm.clamp(0, 50) / 50);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Condition',
          style: TextStyle(color: Color(0xFF60B574)),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF60B574)),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SensorIndicator(
                label: 'CO2',
                value: co2Level,
                normalize: _normalizeCO2,
              ),
              SensorIndicator(
                label: 'NH3',
                value: ammoniaLevel,
                normalize: _normalizeAmmonia,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================
// Sensor Indicator Widget
// ============================
class SensorIndicator extends StatelessWidget {
  final String label;
  final double value;
  final double Function(double) normalize;

  const SensorIndicator({
    required this.label,
    required this.value,
    required this.normalize,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double normalized = normalize(value);
    final bool isCO2 = label.toLowerCase().contains('co');
    final Color progressColor = isCO2 ? const Color(0xFF0BBEDE) : Colors.red;
    final Color backgroundColor =
        isCO2 ? const Color(0xFFB0E0F5) : const Color(0xFFF5B0B0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25.0),
      child: CircularPercentIndicator(
        radius: 110.0,
        lineWidth: 15.0,
        animation: true,
        percent: normalized.clamp(0.0, 1.0),
        center: Text(
          "$label\n${value.toStringAsFixed(isCO2 ? 0 : 1)} ppm",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22.0,
            color: Color(0xFF60B574),
          ),
        ),
        circularStrokeCap: CircularStrokeCap.round,
        progressColor: progressColor,
        backgroundColor: backgroundColor,
      ),
    );
  }
}
