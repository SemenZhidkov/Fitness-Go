import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'create_course_screen.dart';
import 'trainer_profile_form_screen.dart';
import 'requests_screen.dart';
import 'TrainerReviewsViewOnlyScreen.dart';  // Добавьте импорт для нового экрана отзывов

class TrainerProfileScreen extends StatefulWidget {
  @override
  _TrainerProfileScreenState createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends State<TrainerProfileScreen> {
  String _photoUrl = '';
  String _fullName = '';
  int _courseCount = 0;
  double _rating = 0.0;
  int _trainingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadTrainerData();
  }

  Future<void> _loadUserProfile() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();

      if (userDoc.exists) {
        setState(() {
          _photoUrl = userDoc['photoURL'] ?? '';
          _fullName = "${userDoc['name'] ?? ''} ${userDoc['surname'] ?? ''}";
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _loadTrainerData() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Загружаем количество курсов
      QuerySnapshot courseSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('uid', isEqualTo: userId)
          .get();
      setState(() {
        _courseCount = courseSnapshot.docs.length;
      });

      // Загружаем количество тренировок
      QuerySnapshot trainingSnapshot = await FirebaseFirestore.instance
          .collection('Trainings')
          .where('coachId', isEqualTo: userId)
          .get();
      setState(() {
        _trainingCount = trainingSnapshot.docs.length;
      });

      // Загружаем рейтинг тренера
      QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Reviews')
          .get();
      if (reviewSnapshot.docs.isNotEmpty) {
        double totalRating = 0.0;
        reviewSnapshot.docs.forEach((doc) {
          totalRating += doc['rating'];
        });
        setState(() {
          _rating = totalRating / reviewSnapshot.docs.length;
        });
      }
    } catch (e) {
      print('Error loading trainer data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: <Widget>[
          _buildProfileSection(),
          _buildTrainerStats(context),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          CircleAvatar(
            radius: 50,
            backgroundImage: _photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null,
            child: _photoUrl.isEmpty ? Icon(Icons.camera_alt, size: 50) : null,
          ),
          SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fullName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildStarRating(_rating),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, color: Colors.green);
        } else if (index == fullStars && hasHalfStar) {
          return Icon(Icons.star_half, color: Colors.grey);
        } else {
          return Icon(Icons.star_border, color: Colors.grey);
        }
      }),
    );
  }

  Widget _buildTrainerStats(BuildContext context) {
    var theme = Theme.of(context);
    var textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    var backgroundColor = theme.brightness == Brightness.dark ? Colors.black : Colors.white;

    return Container(
      padding: EdgeInsets.all(16.0),
      margin: EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color.fromARGB(255, 6, 98, 77),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          _buildStatRow('Курсы', _courseCount.toString(), textColor),
          _buildStatRow('Рейтинг', _rating.toStringAsFixed(1), textColor),
          _buildStatRow('Тренировки', _trainingCount.toString(), textColor),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(title, style: TextStyle(fontSize: 18, color: textColor)),
          Row(
            children: <Widget>[
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TrainerProfileFormScreen()),
            );
          },
          icon: Icon(Icons.sports, color: Colors.white,), // Иконка свистка
          label: Text('Анкета тренера'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green,  foregroundColor: Colors.white),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateCourseScreen(
                  onCourseCreated: _loadTrainerData, // Обновляем данные после создания курса
                ),
              ),
            );
          },
          child: Text('Создать курс'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrainerReviewsViewOnlyScreen(trainerId: FirebaseAuth.instance.currentUser!.uid),
              ),
            );
          },
          child: Text('Посмотреть отзывы'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
        ),
      ],
    );
  }
}
