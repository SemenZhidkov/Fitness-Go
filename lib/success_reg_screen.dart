import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitnessgo/glav_screen.dart';
import 'package:fitnessgo/glav_screen_athl.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationCompleteScreen extends StatelessWidget {
 
 Future<String> getUserRole() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .get();
      return userDoc['role'] ?? '';
    }
    return '';
  }
 
 Future<void> saveUserToken(String uid, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_token', uid);
    await prefs.setString('user_type', role);
  }
 
  void navigateToProfile(BuildContext context, String role) {
    if (role == 'Тренер') {
       Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CoachProfileScreen()),
        (Route<dynamic> route) => false,
      );
    } else if (role == 'Спортсмен') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AthleteProfileScreen()),
        (Route<dynamic> route) => false,
      );
    } else {
      // Обработайте случай, когда роль не определена
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось определить роль пользователя')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    var backgroundColor = theme.brightness == Brightness.dark ? Colors.black : Colors.white;
    var backgroundImage = theme.brightness == Brightness.dark
        ? AssetImage("assets/dark_back.png")
        : AssetImage("assets/back.png");
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: backgroundImage,
            fit: BoxFit.cover,
          )
        ),
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(height: 180,),
            Image.asset(
              'assets/succes.png', // Убедитесь, что добавили картинку в папку assets и указали здесь правильный путь
              height: 200, // Вы можете настроить размер под свои нужды
            ),
            SizedBox(height: 24), // Расстояние между картинкой и текстом
            Text(
              'Регистрация завершена!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(), // Используется для того, чтобы кнопка была внизу экрана
            ElevatedButton(
              onPressed: () async {
                String role = await getUserRole();
                if (FirebaseAuth.instance.currentUser != null) {
                  await saveUserToken(FirebaseAuth.instance.currentUser!.uid, role);
                  navigateToProfile(context, role);
                }
              },
              child: Text('Вперед!'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(50), // Задаём минимальную высоту для кнопки
                backgroundColor: Color.fromARGB(255, 6, 98, 77),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                textStyle: TextStyle(fontFamily: 'Light', fontWeight: FontWeight.w300, fontSize: 22),
              ),
            ),
            SizedBox(height: 40,),
          ],
        ),
      ),
    );
  }
}
