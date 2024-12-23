import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_set_screen.dart';
import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  final String uid;

  const EmailVerificationScreen({required this.uid, Key? key}) : super(key: key);

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? timer;
  Timer? buttonTimer;
  bool _canResendEmail = true;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      user.sendEmailVerification();

      timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        checkEmailVerified();
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    buttonTimer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser!.reload();
    var user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      timer?.cancel();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ProfileSetupScreen(uid: widget.uid)),
        (route) => false,
      );
    }
  }

  void _startButtonTimer() {
    setState(() {
      _canResendEmail = false;
      _secondsLeft = 120;
    });

    buttonTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _canResendEmail = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendVerificationEmail() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Письмо с подтверждением было отправлено.'),
        ),
      );
      _startButtonTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подтверждение'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              SizedBox(height: 100),
              Text(
                'Мы отправили письмо с подтверждением на вашу электронную почту.',
                style: TextStyle(fontFamily: 'Montserrat', fontSize: 18.0),
                textAlign: TextAlign.center,
              ),
              Spacer(),
              ElevatedButton(
                onPressed: _canResendEmail ? _resendVerificationEmail : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  side: BorderSide(color: Colors.green, width: 2),
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text(
                  _canResendEmail
                      ? 'Отправить письмо еще раз'
                      : 'Подождите $_secondsLeft секунд',
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 15.0, color: Colors.green),
                ),
              ),
              SizedBox(height: 10,),
              Text(
                'Если вы не получили письмо, нажмите кнопку ниже, чтобы отправить еще раз.',
                style: TextStyle(fontFamily: 'Montserrat', fontSize: 10.0),
                textAlign: TextAlign.center,
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
