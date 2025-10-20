import 'dart:async';
import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'splash_screen.dart';
import 'conditions.dart';
import 'history.dart';

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
      Container(),
      ConditionScreen(
        onSensorDataChanged: (co2Value, nh3Value) {
          co2 = co2Value;
          nh3 = nh3Value;
        },
      ),
      HistoryScreen(),
    ];
  }

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
            _openMiHomeApp();
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
// HomeScreen (Statistics + Recommendations)
// ============================
class HomeScreen extends StatefulWidget {
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String? selectedOption;
  final ValueNotifier<List<SensorReading>> _readingsNotifier = ValueNotifier(
    [],
  );
  bool _isLoading = false;
  String _selectedGasView = "Both";
  Timer? _refreshTimer;
  DateTime _lastUpdated = DateTime.now();

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
  void initState() {
    super.initState();
    _loadReadings();

    // 🔁 Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _loadReadings();
    });
  }

  Future<void> _loadReadings() async {
    _isLoading = true;
    final data = await DatabaseHelper().getAllReadings();

    // Map DB rows to SensorReading objects
    final all = data.map((json) => SensorReading.fromJson(json)).toList();

    // Take first 10 readings (oldest)
    final first10 = (all.length <= 10) ? all : all.sublist(0, 10);

    // Reverse for display: 10th reading at 1, 1st at 10
    _readingsNotifier.value = first10.reversed.toList();

    _lastUpdated = DateTime.now();
    _isLoading = false;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _readingsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 260),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: ValueListenableBuilder<List<SensorReading>>(
                          valueListenable: _readingsNotifier,
                          builder: (context, readings, _) {
                            return _buildStatisticsSection(readings);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDropdown(),
                      const SizedBox(height: 20),
                      if (selectedOption != null) _buildRecommendationDetails(),
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

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: _boxDecoration(const Color(0xFF0BBEDE)),
      child: DropdownButton<String>(
        value: selectedOption,
        isExpanded: true,
        hint: const Text(
          "Select Recommendation",
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
        onChanged: (value) => setState(() => selectedOption = value),
      ),
    );
  }

  Widget _buildRecommendationDetails() {
    final selected = recommendations.firstWhere(
      (rec) => rec.title == selectedOption,
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

  Widget _buildStatisticsSection(List<SensorReading> readings) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0BBEDE)),
      );
    }

    if (readings.isEmpty) {
      return const Text("No historical data found.");
    }

    final co2Values = readings.map((r) => r.co2.toDouble()).toList();
    final nh3Values = readings.map((r) => r.ammonia.toDouble()).toList();

    final maxCo2 =
        co2Values.isEmpty ? 0 : co2Values.reduce((a, b) => a > b ? a : b);
    final maxNh3 =
        nh3Values.isEmpty ? 0 : nh3Values.reduce((a, b) => a > b ? a : b);

    double maxY;
    if (_selectedGasView == "NH3") {
      maxY = maxNh3 + 5;
    } else if (_selectedGasView == "CO2") {
      maxY = maxCo2 + 200;
    } else {
      maxY = (maxCo2 > maxNh3 ? maxCo2 + 200 : maxNh3 + 5);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(const Color(0xFF0BBEDE)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📈 Recent Readings (CO₂ & NH₃)",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text("CO₂ Only"),
                selected: _selectedGasView == "CO2",
                onSelected: (_) => setState(() => _selectedGasView = "CO2"),
                selectedColor: Colors.blue.shade100,
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text("NH₃ Only"),
                selected: _selectedGasView == "NH3",
                onSelected: (_) => setState(() => _selectedGasView = "NH3"),
                selectedColor: Colors.green.shade100,
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text("Both"),
                selected: _selectedGasView == "Both",
                onSelected: (_) => setState(() => _selectedGasView = "Both"),
                selectedColor: Colors.cyan.shade100,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx >= 0 && idx < readings.length) {
                          // Reverse X-axis labels
                          int label = readings.length - idx;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label.toString(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY / 5,
                      reservedSize: 40,
                      getTitlesWidget:
                          (value, meta) => Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: maxY / 5,
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  if (_selectedGasView == "CO2" || _selectedGasView == "Both")
                    LineChartBarData(
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      spots: List.generate(
                        co2Values.length,
                        (i) =>
                            FlSpot((i + 1).toDouble(), co2Values[i].toDouble()),
                      ),
                    ),
                  if (_selectedGasView == "NH3" || _selectedGasView == "Both")
                    LineChartBarData(
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      spots: List.generate(
                        nh3Values.length,
                        (i) => FlSpot((i + 1).toDouble(), nh3Values[i] * 1.05),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Last updated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_lastUpdated)}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
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
