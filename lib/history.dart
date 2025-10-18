import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

/// DATABASE HELPER
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await initDB();
    return _database!;
  }

  Future<Database> initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDirectory.path, 'sensor_readings.db');

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT,
        co2 REAL,
        ammonia REAL
      )
    ''');
  }

  Future<void> insertReading(
    String timestamp,
    double co2,
    double ammonia,
  ) async {
    final db = await database;
    await db.insert('readings', {
      'timestamp': timestamp,
      'co2': co2,
      'ammonia': ammonia,
    });
  }

  Future<List<Map<String, dynamic>>> getAllReadings() async {
    final db = await database;
    return await db.query('readings', orderBy: 'id DESC');
  }
}

/// SENSOR READING MODEL
class SensorReading {
  final int? id;
  final double co2;
  final double ammonia;
  final DateTime timestamp;

  SensorReading({
    this.id,
    required this.co2,
    required this.ammonia,
    required this.timestamp,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      id: json['id'] as int?,
      co2: (json['co2'] as num).toDouble(),
      ammonia: (json['ammonia'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// HISTORY SCREEN
class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<SensorReading>> _readingsFuture;

  @override
  void initState() {
    super.initState();
    _readingsFuture = _fetchReadings();
  }

  Future<List<SensorReading>> _fetchReadings() async {
    final rawList = await DatabaseHelper().getAllReadings();
    return rawList.map((json) => SensorReading.fromJson(json)).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _readingsFuture = _fetchReadings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History', style: TextStyle(color: Color(0xFF60B574))),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Color(0xFF60B574)),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<SensorReading>>(
        future: _readingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Color(0xFF60B574)),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading history.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No history found.'));
          }

          final readings = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: EdgeInsets.all(12),
              itemCount: readings.length,
              separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                final r = readings[index];
                // Format timestamp in 12-hour format
                final formattedTime = DateFormat(
                  'yyyy-MM-dd hh:mm:ss a',
                ).format(r.timestamp.toLocal());
                return ListTile(
                  leading: Icon(Icons.history, color: Color(0xFF60B574)),
                  title: Text(
                    'CO₂: ${r.co2.toStringAsFixed(0)} ppm, NH₃: ${r.ammonia.toStringAsFixed(1)} ppm',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    formattedTime,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
