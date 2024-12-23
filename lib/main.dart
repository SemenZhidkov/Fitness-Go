import 'package:fitnessgo/email_verification_screen.dart';
import 'package:fitnessgo/main_set_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitnessgo/registration_screen.dart';
import 'package:fitnessgo/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'glav_screen.dart';
import 'glav_screen_athl.dart';
import 'package:theme_provider/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  bool isLoggedIn = await checkLoginStatus();
  String? userType;
  bool isUserDataComplete = false;

  if (isLoggedIn) {
    userType = await getUserType();
    if (userType != null) {
      isUserDataComplete = await checkUserDataComplete();
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: MyApp(isLoggedIn: isLoggedIn, userType: userType, isUserDataComplete: isUserDataComplete),
    ),
  );
}

Future<bool> checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.containsKey('user_token');
}
  
Future<String?> getUserType() async {
  final prefs = await SharedPreferences.getInstance();
  String? uid = prefs.getString('user_token');
  if (uid == null) {
    return null;
  }
  
  try {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();

    if (!userDoc.exists) {
      return null; // Возвращаем null, если документ не существует
    }

    final data = userDoc.data() as Map<String, dynamic>?; // Приводим данные к Map<String, dynamic> если возможно
    if (data == null || !data.containsKey('role')) {
      return null; // Возвращаем null, если данные отсутствуют или поле 'role' не существует
    }

    return data['role'] as String?;
  } catch (e) {
    // Логируем ошибку для отладки
    print('Error getting user type: $e');
    // Возвращаем null, если произошла ошибка
    return null;
  }
  
}

Future<bool> checkUserDataComplete() async {
  final prefs = await SharedPreferences.getInstance();
  String? uid = prefs.getString('user_token');
  if (uid == null) {
    return false;
  }
  
  try {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();

    if (!userDoc.exists) {
      return false;
    }

    final data = userDoc.data() as Map<String, dynamic>?; 
    if (data == null || data['name'] == null || data['surname'] == null || data['role'] == null || data['choose'] == null) {
      return false;
    }

    return true;
  } catch (e) {
    print('Error checking user data completeness: $e');
    return false;
  }
}

 

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? userType;
  final bool isUserDataComplete;
  MyApp({required this.isLoggedIn, required this.userType, required this.isUserDataComplete});

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
       saveThemesOnChange: true,
        loadThemeOnInit: true,
      themes: [
          AppTheme(
          id: 'light_theme',
          description: 'Light Theme',
          data: ThemeData.light(),
          
          
        ),
         AppTheme(
          id: 'dark_theme',
          description: 'Dark Theme',
          data: ThemeData.dark(),
        ),
      ],
      child: ThemeConsumer(
         child: Builder(
        builder: (themeContext) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeProvider.themeOf(themeContext).data,
           home: isLoggedIn 
              ? (userType == 'Тренер'
                ? CoachProfileScreen()
                : (userType == 'Спортсмен'
                  ? AthleteProfileScreen()
                  : (!isUserDataComplete && FirebaseAuth.instance.currentUser != null
                    ? ProfileSetupScreen(uid: FirebaseAuth.instance.currentUser!.uid)
                    : AuthorizationScreen())))
              : AuthorizationScreen(),
        ),
        ),
      ),
    );
  }
}

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkTheme = false;

  bool get isDarkTheme => _isDarkTheme;

  void setDarkTheme(bool value) {
    _isDarkTheme = value;
    notifyListeners();
  }
}

class AuthorizationScreen extends StatefulWidget {
  const AuthorizationScreen({super.key});

  @override
  AuthorizationScreenState createState() => AuthorizationScreenState();
}

class AuthorizationScreenState extends State<AuthorizationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordHidden = true;

  Future<void> _login() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        String uid = userCredential.user!.uid;

        // Проверяем верифицирована ли почта
        if (!userCredential.user!.emailVerified) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => EmailVerificationScreen(uid: uid)),
          );
          return;
        }

        // Получаем документ пользователя из Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();

        if (!userDoc.exists && userDoc.data() == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfileSetupScreen(uid: uid)),
          );
          return;
        }

        var userData = userDoc.data() as Map<String, dynamic>?;

        if (userData == null || userData['name'] == null || userData['surname'] == null || userData['role'] == null || userData['choose'] == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfileSetupScreen(uid: uid)),
          );
          return;
        }

        String userType = userData['role'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_token', uid);
        await prefs.setString('user_type', userType);

        if (userType == 'Тренер') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => CoachProfileScreen()),
            (route) => false,
          );
        } else if (userType == 'Спортсмен') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => AthleteProfileScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfileSetupScreen(uid: uid)),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка входа: неверный логин или пароль.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    var backgroundColor = theme.brightness == Brightness.dark ? Colors.black : Colors.white;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/back.png"),
            fit: BoxFit.cover,
          ),
        ),
        padding: EdgeInsets.all(18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset('assets/Logo.png', width: 60, height: 60),
                Text(
                  'FitnessGO',
                  style: TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Вход',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegistrationScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      textStyle: TextStyle(fontSize: 35, fontWeight: FontWeight.normal),
                      padding: EdgeInsets.all(10.5),
                    ),
                    child: Text('Создать'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 48),
            TextField(
              controller: _emailController, style: TextStyle(color: Colors.black),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelStyle: TextStyle(fontFamily: 'Light', fontWeight: FontWeight.w300, color: Colors.black),
                hintStyle: TextStyle(color: Colors.black),
                labelText: 'Почта',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController, style: TextStyle(color: Colors.black),
              obscureText: _isPasswordHidden, 
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: 'Пароль',
                hintStyle: TextStyle(decorationColor: textColor),
                labelStyle: TextStyle(fontFamily: 'Light', fontWeight: FontWeight.w300, color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                   
                ),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordHidden ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _isPasswordHidden = !_isPasswordHidden;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 6, 98, 77),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 80, vertical: 10),
                textStyle: TextStyle(fontFamily: 'Light', fontWeight: FontWeight.w400, fontSize: 22),
              ),
              child: Text('Войти'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ResetPasswordScreen()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 6, 98, 77),
                textStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
              child: Text('Забыли пароль?'),
            ),
          ],
        ),
      ),
    );
  }
}