import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class ReportProblemScreen extends StatefulWidget {
  @override
  _ReportProblemScreenState createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final TextEditingController _controller = TextEditingController();
  final String _botToken = '6725119060:AAHWG1LZQp29qzJ6Hr4gkS-buGI5x_5Zfpg'; // Замените на ваш токен бота
  final String _chatId = '-1002137329440'; // Замените на ваш chat_id
  bool _isLoading = false;
  String _userId = '';
  String _userName = '';
  String _userRole = '';
  String _deviceName = '';
  String _deviceOS = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDeviceInfo();
  }
  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot userData =
          await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      setState(() {
        _userId = user.uid;
        _userName = userData['name'];
        _userRole = userData['role'];
      });
    }
  }
  
  Future<void> _loadDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      setState(() {
        _deviceName = androidInfo.model ?? 'Unknown';
        _deviceOS = 'Android ${androidInfo.version.release}';
      });
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      setState(() {
        _deviceName = iosInfo.utsname.machine ?? 'Unknown';
        _deviceOS = 'iOS ${iosInfo.systemVersion}';
      });
    }
  }
  
  Future<void> _sendReport(String message) async {
    setState(() {
      _isLoading = true;
    });

    final String url = 'https://api.telegram.org/bot$_botToken/sendMessage';
    final String fullMessage = 
        "*Message:*\n$message\n\n"
        "*User Info:*\n"
        "Name: $_userName\n"
        "Role: $_userRole\n"
        "ID Firebase: $_userId\n\n"
        "*Device Info:*\n"
        "Device: $_deviceName\n"
        "OS: $_deviceOS";

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'chat_id': _chatId,
          'text': fullMessage,
          'parse_mode': 'Markdown',  // Используем Markdown для форматирования текста
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Сообщение отправлено!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки сообщения.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: Что-то пошло не так, попробуйте позже.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
}

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сообщить о проблеме'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _controller,
                maxLines: 5,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Опишите вашу проблему',
                ),
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity, // Кнопка будет растягиваться на всю ширину
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        onPressed: () {
                          if (_controller.text.isNotEmpty) {
                            _sendReport(_controller.text);
                            _controller.clear();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Пожалуйста, введите сообщение.')),
                            );
                          }
                        },
                        child: Text('Отправить', style: TextStyle(fontSize: 18.0)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}