import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TrainerProfileFormScreen extends StatefulWidget {
  @override
  _TrainerProfileFormScreenState createState() => _TrainerProfileFormScreenState();
}

class _TrainerProfileFormScreenState extends State<TrainerProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String education = '';
  String achievements = '';
  String specialization = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      // Получение идентификатора пользователя (предполагаем, что пользователь уже аутентифицирован)
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Получение документа пользователя из Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('TrainersInfo').doc(userId).get();

      if (userDoc.exists) {
        setState(() {
          education = userDoc['education'] ?? '';
          achievements = userDoc['achievements'] ?? '';
          specialization = userDoc['specialization'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      // Отобразить сообщение об ошибке, если требуется
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Получение идентификатора пользователя
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Сохранение данных в Firebase Firestore
      await FirebaseFirestore.instance.collection('TrainersInfo').doc(userId).set({
        'education': education,
        'achievements': achievements,
        'specialization': specialization,
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Анкета тренера'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    buildSectionTitle('Образование и сертификаты'),
                    TextFormField(
                      initialValue: education,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Введите ваше образование и сертификаты',
                      ),
                      maxLines: 5,
                      onSaved: (value) => education = value!,
                    ),
                    SizedBox(height: 20),
                    buildSectionTitle('Творческие и спортивные достижения'),
                    TextFormField(
                      initialValue: achievements,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Введите ваши достижения',
                      ),
                      maxLines: 5,
                      onSaved: (value) => achievements = value!,
                    ),
                    SizedBox(height: 20),
                    buildSectionTitle('Специализация'),
                    TextFormField(
                      initialValue: specialization,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Введите вашу специализацию',
                      ),
                      maxLines: 5,
                      onSaved: (value) => specialization = value!,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: saveProfile,
                      child: Text('Сохранить'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
