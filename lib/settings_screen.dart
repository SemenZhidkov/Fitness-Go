import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Импортируйте ваш main.dart для доступа к ThemeNotifier
import 'ReportProblem_screen.dart'; // Импортируйте созданный экран
import 'changePass_screnn.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/services.dart';
import 'package:theme_provider/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late BuildContext _currentContext;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentContext = context;
  }

  @override
  Widget build(BuildContext context) {
    return ThemeConsumer(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Настройки', style: GoogleFonts.poppins()),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Центровка по горизонтали
            children: <Widget>[
              Text(
                'Тема',
                style: GoogleFonts.poppins(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // Центровка иконок по горизонтали
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.nights_stay, color: Colors.blueGrey),
                    iconSize: 30.0,
                    onPressed: () {
                      ThemeProvider.controllerOf(context).setTheme('dark_theme');
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.wb_sunny, color: Colors.orange),
                    iconSize: 30.0,
                    onPressed: () {
                      ThemeProvider.controllerOf(context).setTheme('light_theme');
                    },
                  ),
                ],
              ),
              SizedBox(height: 30.0),
              buildButton(context, 'Сменить пароль', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
                );
              }),
              buildButton(context, 'Сообщить о проблеме', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReportProblemScreen()),
                );
              }),
              //TODO: Верификация будет в дальнейших обновлениях
              
              buildButton(context, 'Выйти из аккаунта', () async {
                await _signOut(context);
              }),
              buildButton(context, 'Удалить аккаунт', () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    final TextEditingController passwordController = TextEditingController();
                    return AlertDialog(
                      title: Text('Удалить аккаунт', style: GoogleFonts.poppins()),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Вы действительно хотите удалить аккаунт? Это действие необратимо.', style: GoogleFonts.poppins()),
                          TextField(
                            controller: passwordController,
                            decoration: InputDecoration(labelText: 'Введите пароль'),
                            obscureText: true,
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Нет', style: GoogleFonts.poppins()),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text('Да', style: GoogleFonts.poppins()),
                          onPressed: () async {
                            final String password = passwordController.text;
                            Navigator.of(context).pop(); // Закрыть диалоговое окно
                            await _deleteAccount(_currentContext, password); // Используем сохраненный контекст и введенный пароль
                          },
                        ),
                      ],
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildButton(BuildContext context, String text, VoidCallback onPressed) {
    var theme = Theme.of(context);
    var textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    var backgroundColor = theme.brightness == Brightness.dark ? Colors.black : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity, // Кнопка будет растягиваться на всю ширину
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor, // Белый цвет фона
            foregroundColor: Colors.green, // Зеленый цвет текста
            side: BorderSide(color: Colors.green, width: 2), // Зеленый бордер
            padding: EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: GoogleFonts.montserrat(fontSize: 18.0, color: Colors.green),
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await DefaultCacheManager().emptyCache();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => AuthorizationScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _deleteAccount(BuildContext context, String password) async {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user = _auth.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Пользователь не найден')),
    );
    return;
  }

  try {
    // Reauthenticate the user
    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password, // Замените на пароль, введенный пользователем для подтверждения
    );

    await user.reauthenticateWithCredential(credential);

    // Delete user's data from Firestore
    await _deleteUserData(user.uid);

    // Delete the user
    await user.delete();
    await DefaultCacheManager().emptyCache();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Аккаунт успешно удален')),
    );

    // Start screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => AuthorizationScreen()),
      (Route<dynamic> route) => false,
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка: ${e.toString()}')),
    );
  }
}

Future<void> _deleteUserData(String userId) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Удаляем пользователя из коллекции Users
  await firestore.collection('Users').doc(userId).delete();

  // Удаляем тренировки пользователя из коллекции Trainings
  QuerySnapshot trainingsSnapshot = await firestore
      .collection('Trainings')
      .where('coachId', isEqualTo: userId)
      .get();
  for (DocumentSnapshot doc in trainingsSnapshot.docs) {
    await doc.reference.delete();
  }

  // Удаляем тренировки, в которых пользователь является участником
  QuerySnapshot participantTrainingsSnapshot = await firestore
      .collection('Trainings')
      .where('participants', arrayContains: userId)
      .get();
  for (DocumentSnapshot doc in participantTrainingsSnapshot.docs) {
    await doc.reference.update({
      'participants': FieldValue.arrayRemove([userId])
    });
  }

  // Удаляем все чаты пользователя
  QuerySnapshot chatsSnapshot = await firestore
      .collection('chats')
      .where('users', arrayContains: userId)
      .get();
  for (DocumentSnapshot chatDoc in chatsSnapshot.docs) {
    await chatDoc.reference.delete();
  }

  // Удаляем курсы пользователя
  QuerySnapshot coursesSnapshot = await firestore
      .collection('courses')
      .where('uid', isEqualTo: userId)
      .get();
  for (DocumentSnapshot doc in coursesSnapshot.docs) {
    await doc.reference.delete();
  }

  // Удаляем запросы пользователя
  QuerySnapshot requestsSnapshot = await firestore
      .collection('Users')
      .doc(userId)
      .collection('Requests')
      .get();
  for (DocumentSnapshot doc in requestsSnapshot.docs) {
    await doc.reference.delete();
  }

  // Удаляем отзывы пользователя
  QuerySnapshot reviewsSnapshot = await firestore
      .collection('Users')
      .doc(userId)
      .collection('Reviews')
      .get();
  for (DocumentSnapshot doc in reviewsSnapshot.docs) {
    await doc.reference.delete();
  }

  // Удаляем питание пользователя
  QuerySnapshot mealsSnapshot = await firestore
      .collection('Users')
      .doc(userId)
      .collection('Meals')
      .get();
  for (DocumentSnapshot doc in mealsSnapshot.docs) {
    await doc.reference.delete();
  }

  // Удаляем вес пользователя
  DocumentSnapshot weightDoc = await firestore
      .collection('Users')
      .doc(userId)
      .get();
  if (weightDoc.exists) {
    await weightDoc.reference.update({
      'weightData': FieldValue.delete(),
    });
  }
}
}