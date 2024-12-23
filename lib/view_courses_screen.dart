import 'package:fitnessgo/course_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:theme_provider/theme_provider.dart';

class CoursesScreen extends StatefulWidget {
  @override
  _CoursesScreenState createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  late Future<String?> userRoleFuture;
  late Stream<List<Course>> coursesStream;

  @override
  void initState() {
    super.initState();
    userRoleFuture = getUserRole();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.themeOf(context).data;
    return Scaffold(
      appBar: AppBar(
        title: Text('Курсы'),
      ),
      body: FutureBuilder<String?>(
        future: userRoleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Не удалось получить роль пользователя'));
          }

          String role = snapshot.data!;
          coursesStream = getCourses(role);

          return StreamBuilder<List<Course>>(
            stream: coursesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Ошибка: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('Курсы не найдены'));
              }

              List<Course> courses = snapshot.data!;

              return ListView.builder(
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  Course course = courses[index];
                  return ListTile(
                    title: Text(course.title),
                    subtitle: Text('Наименование: ${course.description}'),
                    onTap: () {
                      // Открытие подробного просмотра курса
                            Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetailScreen(courseId: course.id),
                      ),
                    );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class Course {
  final String id;
  final String title;
  final String description;
  final String trainerId;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.trainerId,
  });

  factory Course.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Course(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      trainerId: data['trainerId'] ?? '',
    );
  }
}

Future<String?> getUserRole() async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(currentUser.uid).get();
    return userDoc['role'];
  }
  return null;
}

Stream<List<Course>> getCourses(String role) {
  CollectionReference coursesCollection = FirebaseFirestore.instance.collection('courses');

  if (role == 'Тренер') {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    return coursesCollection.where('uid', isEqualTo: userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Course.fromFirestore(doc)).toList();
    });
  } else {
    return coursesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Course.fromFirestore(doc)).toList();
    });
  }
}
