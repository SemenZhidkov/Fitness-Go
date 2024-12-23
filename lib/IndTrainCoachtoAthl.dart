import 'package:fitnessgo/onChat_field_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CreateIndividualTrainingScreen extends StatefulWidget {
  @override
  _CreateIndividualTrainingScreenState createState() => _CreateIndividualTrainingScreenState();
}

class _CreateIndividualTrainingScreenState extends State<CreateIndividualTrainingScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedUserId;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
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
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _createTrainingSession() async {
    if (_selectedUserId == null || _selectedDate == null || _selectedTime == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пожалуйста, заполните все поля')),
      );
      return;
    }

    final DateTime trainingDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      var trainingRef = await FirebaseFirestore.instance.collection('IndividualTrainings').add({
        'coachId': currentUser.uid,
        'date': trainingDateTime,
        'description': _descriptionController.text,
        'participants': [_selectedUserId, currentUser.uid],
        'title': 'Индивидуальная тренировка',
        'isIndividual': true,
      });

      await _sendTrainingMessage(
        context,
        _selectedUserId!,
        'Индивидуальная тренировка',
        trainingDateTime,
        _descriptionController.text,
        trainingRef.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Индивидуальная тренировка создана')),
      );

      Navigator.pop(context);
    }
  }

  Future<void> _sendTrainingMessage(BuildContext context, String userId, String trainingName, DateTime dateTime, String description, String trainingId) async {
  var currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    final chatId = getChatId(currentUser.uid, userId);
    var formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
    var message = 'У вас запланирована индивидуальная тренировка на $formattedDate\n$description';

    var chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    var chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'users': [currentUser.uid, userId],
      });
    } else {
      await chatRef.update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }

    await chatRef.collection('messages').add({
      'text': message,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': currentUser.uid,
      'isRead': false,
      'trainingId': trainingId,
      'icon': 'whistle',
      'iconColor': 'green',
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Создать индивидуальную тренировку'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text(
                _selectedDate == null
                    ? 'Выберите дату'
                    : 'Дата: ${DateFormat('dd.MM.yyyy').format(_selectedDate!)}',
              ),
            ),
            ElevatedButton(
              onPressed: () => _selectTime(context),
              child: Text(
                _selectedTime == null
                    ? 'Выберите время'
                    : 'Время: ${_selectedTime!.format(context)}',
              ),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Описание тренировки'),
            ),
            SizedBox(height: 20),
            Text(
              'Выберите подопечного:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('Requests')
                    .where('status', isEqualTo: 'approved')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final reviews = snapshot.data!.docs;
                  if (reviews.isEmpty) {
                    return Center(child: Text('Нет подтвержденных подопечных'));
                  }
                  return ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('Users').doc(review['userId']).get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return ListTile(
                              title: Text('Загрузка...'),
                            );
                          }
                          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: userData['photoURL'] != null
                                  ? NetworkImage(userData['photoURL'])
                                  : null,
                              child: userData['photoURL'] == null
                                  ? Icon(Icons.person)
                                  : null,
                            ),
                            title: Text('${userData['name']} ${userData['surname']}'),
                            onTap: () {
                              setState(() {
                                _selectedUserId = review['userId'];
                              });
                            },
                            selected: _selectedUserId == review['userId'],
                            selectedTileColor: Colors.grey[200],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createTrainingSession,
              child: Text('Создать тренировку'),
            ),
          ],
        ),
      ),
    );
  }
}
