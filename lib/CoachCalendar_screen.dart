import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'CoachTrainCheck.dart';

class CoachScheduleScreen extends StatefulWidget {
  @override
  _CoachScheduleScreenState createState() => _CoachScheduleScreenState();
}

class _CoachScheduleScreenState extends State<CoachScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _trainingSessions = {};

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru_RU', null).then((_) => _loadCoachWorkouts());
  }

  void _loadCoachWorkouts() {
    var currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('Trainings')
          .where('coachId', isEqualTo: currentUser.uid)
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
          var date = (workoutData['date'] as Timestamp).toDate().toLocal();
          var dateKey = DateTime(date.year, date.month, date.day);

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
        }

        setState(() {
          _trainingSessions = newTrainingSessions;
          print("Updated training sessions: $_trainingSessions");
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building CoachScheduleScreen with selected day: $_selectedDay");
    print("Training sessions for selected day: ${_trainingSessions[_selectedDay]}");

    return Scaffold(
      body: Column(
        children: <Widget>[
          TableCalendar(
            locale: 'ru_RU',
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            availableCalendarFormats: const {CalendarFormat.month: 'Месяц'},
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              print("Selected day: $selectedDay");
              print("Training sessions for selected day: ${_trainingSessions[selectedDay]}");
            },
            eventLoader: (day) {
              final events = _trainingSessions[DateTime(day.year, day.month, day.day)] ?? [];
              print("Events for $day: $events");
              return events;
            },
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
              itemCount: _trainingSessions[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)]?.length ?? 0,
              itemBuilder: (context, index) {
                var session = _trainingSessions[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)]![index];
                return ListTile(
                  title: Text(session['title']),
                  subtitle: Text("${DateFormat('dd.MM в HH:mm').format(session['date'])} - ${session['description']}"),
                  onTap: session['title'] == 'Индивидуальная тренировка'
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
