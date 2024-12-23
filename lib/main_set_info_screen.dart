import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'success_reg_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class UserInfoScreen extends StatefulWidget {
  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  Future<void> _uploadUserInfo() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      try {
        String? photoUrl;

        // Проверяем, выбрано ли изображение пользователем
        if (_image != null) {
          // Получаем уникальный идентификатор пользователя
          String userId = FirebaseAuth.instance.currentUser!.uid;
          
          // Загрузка изображения в Firebase Storage
          File imageFile = File(_image!.path);
          TaskSnapshot snapshot = await FirebaseStorage.instance
            .ref('user_images/$userId.jpg')
            .putFile(imageFile);
            
          // Получаем URL загруженного изображения
          photoUrl = await snapshot.ref.getDownloadURL();
        }

        // Сохранение информации пользователя в Firestore
        var user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
          'photoURL': photoUrl,
          'name': _firstName,
          'surname': _lastName,
          'birthday': _birthDate != null ? DateFormat('dd.MM.yyyy').format(_birthDate!) : null,
          // Другие поля, если необходимо
          }, SetOptions(merge: true)); // Используйте merge, чтобы обновлять существующие данные, не удаляя другие поля
        }

        // Переход к экрану успешной регистрации
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RegistrationCompleteScreen()),
        );

      } catch (e) {
        // Если возникает ошибка, отобразите соответствующее сообщение
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при сохранении данных: $e')),
        );
      }
    }
  }
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  String _firstName = '';
  String _lastName = '';
  DateTime? _birthDate = DateTime.now();
  XFile? _image;

  final ImagePicker _picker = ImagePicker();
  
  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  // Метод для выбора фотографии
  Future<void> _pickAndCropImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      final croppedImage = await ImageCropper().cropImage(
        sourcePath: pickedImage.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Редактирование',
            toolbarColor: Color.fromARGB(255, 6, 98, 77),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Редактирование',
          ),
        ],
      );
      if (croppedImage != null) {
        setState(() {
          _image = XFile(croppedImage.path);
        });
      }
    }
  }

  void _showDatePicker(BuildContext context) {
    var theme = Theme.of(context);
    var textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    var backgroundColor = theme.brightness == Brightness.dark ? Colors.black : Colors.white;
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (_) => Container(
          height: 300,
          color: backgroundColor,
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  initialDateTime: _birthDate,
                  mode: CupertinoDatePickerMode.date,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() => _birthDate = newDate);
                  },
                ),
              ),
              CupertinoButton(child: Text('OK', style: TextStyle(color:textColor),), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      );
    } else {
      // Показать Material DatePicker
      showDatePicker(
        context: context,
        initialDate: _birthDate ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      ).then((pickedDate) {
        if (pickedDate != null && pickedDate != _birthDate) {
          setState(() {
            _birthDate = pickedDate;
          });
        }
      });
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
        _dateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
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
      appBar: AppBar(
        title: LinearProgressIndicator(
          value: 0.75, // Прогресс 4 из 4
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 32, 151, 69)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: backgroundImage, 
              fit: BoxFit.cover,
            ),
          ),
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Распределение пространства между дочерними виджетами
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'ШАГ 3/4',
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.normal, 
                    fontFamily: 'Montserrat',
                    color: textColor,
                  ),
                ),
              ),
              Text(
                'Немного о себе',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 26,
                  color: textColor,
                ),
              ),
              GestureDetector(
                onTap: _pickAndCropImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _image != null ? FileImage(File(_image!.path)) : null,
                  child: _image == null ? Icon(Icons.camera_alt, size: 50, color: textColor) : null,
                ),
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Имя',
                  labelStyle: TextStyle(color: textColor),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста введите свое имя.';
                  }
                  return null;
                },
                onSaved: (value) => _firstName = value!,
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Фамилия',
                  labelStyle: TextStyle(color: textColor),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста введите свою фамилию.';
                  }
                  return null;
                },
                onSaved: (value) => _lastName = value!,
              ),
              GestureDetector(
                onTap: () => _showDatePicker(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: _birthDate != null ? DateFormat('dd.MM.yyyy').format(_birthDate!) : '',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Дата рождения',
                      labelStyle: TextStyle(color: textColor),
                      hintText: _birthDate == null ? 'Выберите дату' : DateFormat('dd.MM.yyyy').format(_birthDate!),
                      suffixIcon: Icon(Icons.calendar_today, color: textColor),
                    ),
                    validator: (value) {
                      if (_birthDate == null) {
                        return 'Пожалуйста выберите дату рождения.';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(height: 110),
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: double.infinity, // Растягиваем на всю ширину
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        await _uploadUserInfo();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 6, 98, 77),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      textStyle: TextStyle(fontFamily: 'Light', fontWeight: FontWeight.w300, fontSize: 22),
                    ),
                    child: Text('Продолжить'),
                  ),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
