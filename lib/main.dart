import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

import 'splash_screen.dart';
import 'conditions.dart'; // ConditionScreen
import 'history.dart'; // HistoryScreen

void main() {
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: SplashScreen()));
}

// ============================
// Recommendation Model
// ============================
class GasRecommendation {
  final String title;
  final String status;
  final List<String> details;

  GasRecommendation({
    required this.title,
    required this.status,
    required this.details,
  });
}

// ============================
// MainScreen with BottomNavigationBar
// ============================
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  double co2 = 0.0;
  double nh3 = 0.0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(),
      Container(), // Purifier placeholder (intent handled separately)
      ConditionScreen(
        onSensorDataChanged: (co2Value, nh3Value) {
          co2 = co2Value;
          nh3 = nh3Value;
        },
      ),
      HistoryScreen(), // History tab
    ];
  }

  // Open Mi Home app
  void _openMiHomeApp() async {
    const packageName = 'com.xiaomi.smarthome';
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
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            _openMiHomeApp(); // Open Mi Home app
            return;
          }
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.air), label: "Purifier"),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: "Conditions",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        ],
        selectedItemColor: Color(0xFF0BBEDE),
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

// ============================
// HomeScreen (Recommendations)
// ============================
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedRecommendation;

  final List<GasRecommendation> recommendations = [
    GasRecommendation(
      title: 'NH3: 0–10 ppm',
      status: '✅ Optimal',
      details: [
        'Maintain current ventilation and litter management practices.',
        'Continue regular monitoring to ensure levels remain low.',
      ],
    ),
    GasRecommendation(
      title: 'NH3: 11–25 ppm',
      status: '⚠️ Moderate',
      details: [
        'Enhance ventilation to reduce NH₃ accumulation.',
        'Inspect and repair any water leaks to prevent litter dampness.',
        'Consider using litter amendments to bind ammonia.',
      ],
    ),
    GasRecommendation(
      title: 'NH3: >25 ppm',
      status: '❌ High',
      details: [
        'Implement immediate ventilation improvements.',
        'Remove and replace wet or soiled litter.',
        'Evaluate and adjust stocking density if necessary.',
      ],
    ),
    GasRecommendation(
      title: 'CO₂: 0–2000 ppm',
      status: '✅ Optimal',
      details: [
        'Maintain current ventilation systems.',
        'Continue routine monitoring of CO₂ levels.',
      ],
    ),
    GasRecommendation(
      title: 'CO₂: 2001–3000 ppm',
      status: '⚠️ Moderate',
      details: [
        'Increase ventilation rates to enhance air exchange.',
        'Check for and address any sources of CO₂ accumulation.',
      ],
    ),
    GasRecommendation(
      title: 'CO₂: >3000 ppm',
      status: '❌ High',
      details: [
        'Implement immediate ventilation improvements.',
        'Inspect and service heating systems to ensure proper combustion.',
        'Reduce stocking density if overcrowding is contributing.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background
        Column(
          children: [
            ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: 0.5,
                child: Image.asset(
                  'assets/splashscreen.jpg',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: Image.asset(
                'assets/plainbg.png',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),

        // Foreground content
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 260),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildRecommendationsDropdown(),
                      const SizedBox(height: 20),
                      if (selectedRecommendation != null)
                        _buildRecommendationDetails(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: _boxDecoration(const Color(0xFF0BBEDE)),
      child: DropdownButton<String>(
        value: selectedRecommendation,
        isExpanded: true,
        hint: const Text(
          "Recommendations",
          style: TextStyle(color: Color(0xFF0BBEDE), fontSize: 18),
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0BBEDE)),
        underline: const SizedBox(),
        items:
            recommendations
                .map(
                  (rec) => DropdownMenuItem<String>(
                    value: rec.title,
                    child: Text('${rec.title} – ${rec.status}'),
                  ),
                )
                .toList(),
        onChanged: (value) {
          setState(() {
            selectedRecommendation = value;
          });
        },
      ),
    );
  }

  Widget _buildRecommendationDetails() {
    final selected = recommendations.firstWhere(
      (rec) => rec.title == selectedRecommendation,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(const Color(0xFF0BBEDE)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            selected.details
                .map(
                  (detail) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(detail),
                  ),
                )
                .toList(),
      ),
    );
  }

  BoxDecoration _boxDecoration(Color borderColor) {
    return BoxDecoration(
      color: Colors.white,
      border: Border.all(color: borderColor, width: 1.5),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          spreadRadius: 2,
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
