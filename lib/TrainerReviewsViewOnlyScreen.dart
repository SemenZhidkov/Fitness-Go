import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrainerReviewsViewOnlyScreen extends StatefulWidget {
  final String trainerId;

  TrainerReviewsViewOnlyScreen({required this.trainerId});

  @override
  _TrainerReviewsViewOnlyScreenState createState() => _TrainerReviewsViewOnlyScreenState();
}

class _TrainerReviewsViewOnlyScreenState extends State<TrainerReviewsViewOnlyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Отзывы о тренере'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(widget.trainerId)
            .collection('Reviews')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final reviews = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return ListTile(
                leading: Icon(Icons.star, color: Colors.green),
                title: Text(review['text']),
                subtitle: Text('Оценка: ${review['rating']}'),
              );
            },
          );
        },
      ),
    );
  }
}
