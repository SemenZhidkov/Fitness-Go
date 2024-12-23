import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'TrainDetailsnew.dart';

class UserWorkoutScreen extends StatefulWidget {
  @override
  _UserWorkoutScreenState createState() => _UserWorkoutScreenState();
}

class _UserWorkoutScreenState extends State<UserWorkoutScreen> {
  Stream<List<QueryDocumentSnapshot>> _getWorkouts() {
    return FirebaseFirestore.instance
        .collection('Trainings')
        .where('title', isNotEqualTo: 'Индивидуальная тренировка') // Фильтр для исключения индивидуальных тренировок
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: _getWorkouts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Нет доступных тренировок"));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data![index];
              var data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['title']),
                subtitle: Text("${DateFormat('dd.MM.yyyy HH:mm').format(data['date'].toDate())} - Вместимость: ${data['capacity']}"),
                trailing: IconButton(
                  icon: Icon(Icons.info_outline),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutDetailScreen(workoutId: doc.id),
                    ),
                  ),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutDetailScreen(workoutId: doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
