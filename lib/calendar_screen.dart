import 'package:fitnessgo/train_detail_check.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<dynamic>> _trainingSessions = {};

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru_RU', null).then((_) => _loadUserWorkouts());
  }

  void _loadUserWorkouts() {
    var currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('Trainings')
          .where('participants', arrayContains: currentUser.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isEmpty) {
          print("No training sessions found for user: ${currentUser.uid}");
        } else {
          print("Found ${snapshot.docs.length} training sessions");
        }

        Map<DateTime, List<Map<String, dynamic>>> newTrainingSessions = {};
        for (var doc in snapshot.docs) {
          var workoutData = doc.data() as Map<String, dynamic>;
          var date = (workoutData['date'] as Timestamp).toDate().toUtc();
          var dateKey = DateTime.utc(date.year, date.month, date.day);

          if (!newTrainingSessions.containsKey(dateKey)) {
            newTrainingSessions[dateKey] = [];
          }

          newTrainingSessions[dateKey]?.add({
            'title': workoutData['title'],
            'description': workoutData['description'],
            'time': DateFormat('HH:mm').format(date),
            'date': date,
            'workoutId': doc.id,
            'isIndividual': workoutData['title'] == 'Индивидуальная тренировка',
          });

          print("Added workout to sessions: ${newTrainingSessions[dateKey]}");
        }

        setState(() {
          _trainingSessions = newTrainingSessions;
          print("State updated with new training sessions");
        });
      });
    } else {
      print("No current user found");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building Schedule Screen with selected day: $_selectedDay");
    print("Training sessions for selected day: ${_trainingSessions[_selectedDay]}");
    return Scaffold(
      body: Column(
        children: <Widget>[
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            availableCalendarFormats: const {CalendarFormat.month: 'Месяц'},
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              var formattedSelectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
              print("Selected day: $formattedSelectedDay");
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) => _trainingSessions[DateTime.utc(day.year, day.month, day.day)] ?? [],
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.green.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return SizedBox();
                final isIndividual = events.any((event) => (event as Map<String, dynamic>)['isIndividual'] == true);
                return Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isIndividual ? Colors.orange : Colors.green,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _trainingSessions[_selectedDay]?.length ?? 0,
              itemBuilder: (context, index) {
                var session = _trainingSessions[_selectedDay]![index];
                return ListTile(
                  title: Text(session['title']),
                  subtitle: Text("${DateFormat('dd.MM в HH:mm').format(session['date'].toLocal())} - ${session['description']}"),
                  onTap: (session['isIndividual'] == true)
                      ? null
                      : () {
                          if (session.containsKey('workoutId') && session['workoutId'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TrainDetailCheck(trainingId: session['workoutId']),
                              ),
                            );
                          } else {
                            print("Workout ID is null or missing for this session");
                          }
                        },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
