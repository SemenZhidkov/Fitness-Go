// ignore_for_file: prefer_const_constructors


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'maps/mainmap.dart';



class AddTrainingScreen extends StatefulWidget {
  @override
  _AddTrainingScreenState createState() => _AddTrainingScreenState();
}

class _AddTrainingScreenState extends State<AddTrainingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  int _capacity = 1;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  Point? _selectedLocation;
  String? _selectedCenterName;
  String? _selectedCenterAddress;
  String? _selectedCenterLogo;

  final List<Map<String, dynamic>> fitnessCategories = [
    {'name': 'Йога', 'icon': 'assets/icons/yoga.svg'},
    {'name': 'Силовые', 'icon': 'assets/icons/sila.svg'},
    {'name': 'Кардио', 'icon': 'assets/icons/cardio.svg'},
    {'name': 'Массонабор', 'icon': 'assets/icons/massnab.svg'},
    {'name': 'Поддержание', 'icon': 'assets/icons/poderzh.svg'},
    {'name': 'Похудение', 'icon': 'assets/icons/pohud.svg'},
    {'name': 'ПП', 'icon': 'assets/icons/applepit.svg'},
    {'name': 'Инт. питание', 'icon': 'assets/icons/intlpit.svg'},
    {'name': 'Вегетарианец', 'icon': 'assets/icons/vegetar.svg'},
  ];

  List<bool> _selectedCategories = List.filled(9, false);

  void _submitForm() {
  final DateTime fullDateTime = DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _selectedTime.hour,
    _selectedTime.minute,
  );
  final Timestamp trainingTimestamp = Timestamp.fromDate(fullDateTime);
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null && _nameController.text.isNotEmpty && _selectedLocation != null) {
    final trainingData = {
      'title': _nameController.text,
      'description': _descriptionController.text,
      'date': trainingTimestamp,
      'capacity': _capacity,
      'categories': fitnessCategories
          .where((category) => _selectedCategories[fitnessCategories.indexOf(category)])
          .map((category) => category['name'])
          .toList(),
      'coachId': currentUser.uid,
      'centerName': _selectedCenterName,
      'centerAddress': _selectedCenterAddress,
      'centerLogo': _selectedCenterLogo,
      'location': GeoPoint(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      ), // Save the selected location
    };

    FirebaseFirestore.instance.collection('Trainings').add(trainingData);
    Navigator.pop(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Пожалуйста, заполните все поля и выберите клуб')),
    );
  }
}


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      final selectedData = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MapScreen()),
      );
      if (selectedData != null) {
        setState(() {
          _selectedCenterName = selectedData['name'];
          _selectedCenterAddress = selectedData['address'];
          _selectedCenterLogo = selectedData['logo'];
          _selectedLocation = selectedData['location'];
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission is required to select a place')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Создать тренировку"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Название тренировки'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Введите название тренировки';
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Описание'),
                maxLines: 5,
              ),
              ListTile(
                title: Text("Дата занятия: ${DateFormat('dd.MM.yyyy').format(_selectedDate)}"),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              ListTile(
                title: Text("Время тренировки: ${_selectedTime.format(context)}"),
                trailing: Icon(Icons.timer),
                onTap: () => _selectTime(context),
              ),
              Row(
                children: [
                  Expanded(child: Text('Максимальное количество участников')),
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      if (_capacity > 1) {
                        setState(() {
                          _capacity--;
                        });
                      }
                    },
                  ),
                  Text('$_capacity'),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        _capacity++;
                      });
                    },
                  ),
                ],
              ),
              GridView.builder(
                shrinkWrap: true,
                itemCount: fitnessCategories.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategories[index] = !_selectedCategories[index];
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedCategories[index] ? Colors.lightGreen[400] : Colors.grey[400],
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SvgPicture.asset(
                            fitnessCategories[index]['icon'],
                            width: 20,
                            height: 20,
                          ),
                          Text(
                            fitnessCategories[index]['name'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (_selectedCenterName != null && _selectedCenterAddress != null)
                ListTile(
                  title: Text("Выбранный клуб: $_selectedCenterName"),
                  subtitle: Text("Адрес: $_selectedCenterAddress"),
                ),
              ElevatedButton(
                onPressed: _requestLocationPermission,
                child: Text('Выбрать место'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50), // Width and height
                ),
              ),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
