import 'package:flutter/material.dart';

void main() {
  runApp(MySimpleCoopApp());
}

class MySimpleCoopApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Coop Monitor',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[100],
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {},
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coop', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            Center(
              child: Icon(Icons.home, size: 100),
            ),
            SizedBox(height: 32),
            Text('Air Quality', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            QualityTile(
              title: 'Carbon Dioxide',
              isSafe: true,
            ),
            SizedBox(height: 8),
            QualityTile(
              title: 'Ammonia',
              isSafe: false,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Condition',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.recommend),
            label: 'Recommend',
          ),
        ],
      ),
    );
  }
}

class QualityTile extends StatelessWidget {
  final String title;
  final bool isSafe;

  const QualityTile({required this.title, required this.isSafe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.air, color: Colors.grey),
          SizedBox(width: 12),
          Expanded(child: Text(title)),
          Icon(
            isSafe ? Icons.check_circle : Icons.error,
            color: isSafe ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }
}
