import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

import 'package:theme_provider/theme_provider.dart';

class StatScreen extends StatefulWidget {
  @override
  _StatScreenState createState() => _StatScreenState();
}

class _StatScreenState extends State<StatScreen> {
  List<double> weightData = [];
  double totalWater = 0;
  User? currentUser;

  @override
  void initState() {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
    super.initState();
    _loadWeightData();
    _loadWaterData();
    }
  }

  Future<void> _loadWeightData() async {
    if (currentUser == null) return;
    final doc = await FirebaseFirestore.instance.collection('Users').doc(currentUser!.uid).get();
   if (doc.exists) {
      setState(() {
        weightData = List<double>.from(doc.data()?['weightData'] ?? []);
      });
    }
  }

  Future<void> _saveWeightData() async {
    if (currentUser == null) return;

    await FirebaseFirestore.instance.collection('Users').doc(currentUser!.uid).set(
      {'weightData': weightData},
      SetOptions(merge: true),
    );
  }
  

  Future<void> _loadWaterData() async {
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance.collection('Users').doc(currentUser!.uid).get();
    if (doc.exists) {
      final data = doc.data();
      final waterTimestamp = data?['waterTimestamp']?.toDate() ?? DateTime.now();
      final currentTime = DateTime.now();
      if (_isSameDay(waterTimestamp, currentTime)) {
        setState(() {
          totalWater = data?['totalWater'] ?? 0;
        });
      } else {
        // Reset water consumption if the day has changed
        setState(() {
          totalWater = 0;
        });
        _saveWaterData(reset: true);
      }
    }
    }

  Future<void> _saveWaterData({bool reset = false}) async {
    if (currentUser == null) return;

    final data = {
      'totalWater': totalWater,
      'waterTimestamp': reset ? FieldValue.serverTimestamp() : DateTime.now(),
    };

    await FirebaseFirestore.instance.collection('Users').doc(currentUser!.uid).set(
      data,
      SetOptions(merge: true),
    );
  }

  

  void _addWeight(double weight) {
    setState(() {
      if (weightData.length == 10) {
        weightData.removeAt(0);
      }
      weightData.add(weight);
      _saveWeightData();
    });
  }

  void _incrementWater() {
    setState(() {
        totalWater += 0.2;
        _saveWaterData();
    });
  }

  void _decrementWater() {
    setState(() {
      if (totalWater > 0.1) {
        totalWater -= 0.2;
        _saveWaterData();
      }
      else {
        totalWater = 0.0;
      }
    });
  }
 
  bool _isSameDay(DateTime date1, DateTime date2) {
      return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
    }
  

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.themeOf(context).data;
    return ThemeConsumer(
      child: Scaffold(
      appBar: AppBar(
        title: Text('Активность и здоровье'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildWeightChart(),
              SizedBox(height: 20),
              _buildWaterTracker(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildWeightChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Вес', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            SizedBox(
              height: 200, // Задаем фиксированную высоту для LineChart
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false, border: Border.all(color: Color.fromARGB(31, 255, 255, 255))),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weightData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: Color.fromARGB(255, 6, 98, 77),
                      barWidth: 3,
                    )
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                double? newWeight = await _showAddWeightDialog();
                if (newWeight != null) {
                  _addWeight(newWeight);
                }
              },
              child: Text('Добавить вес', style: TextStyle(color: Color.fromARGB(255, 6, 98, 77),),),
            ),
          ],
        ),
      ),
    );
  }

  Future<double?> _showAddWeightDialog() async {
    TextEditingController controller = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Введите вес'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: 'Вес в кг'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(double.tryParse(controller.text));
              },
              child: Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWaterTracker() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Вода', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: _decrementWater,
                ),
                Text('${totalWater.toStringAsFixed(1)} л', style: TextStyle(fontSize: 18)),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _incrementWater,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
