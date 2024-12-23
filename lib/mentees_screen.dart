import 'package:fitnessgo/NutritionScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'TrainDetailsnew.dart';
import 'onChat_field_screen.dart'; // Импорт экрана деталей тренировки

class MenteesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Подопечные'),
        ),
        body: Center(child: Text('Пользователь не авторизован')),
      );
    }

    String trainerId = currentUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Подопечные'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(trainerId)
            .collection('Requests')
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Нет подопечных'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var requestData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              var requestId = snapshot.data!.docs[index].id;
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('Users').doc(requestData['userId']).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return ListTile(
                      title: Text('Неизвестный пользователь'),
                    );
                  }

                  var userData = userSnapshot.data!.data() as Map<String, dynamic>;

                  return Dismissible(
                    key: Key(requestId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(Icons.delete, color: Colors.white, size: 32),
                    ),
                    onDismissed: (direction) {
                      _removeMentee(requestId);
                      Navigator.of(context).pop();
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(userData['photoURL'] ?? 'URL_ЗАГЛУШКИ_ИЗОБРАЖЕНИЯ'),
                        radius: 30,
                      ),
                      title: Text('${userData['name']} ${userData['surname']}'),
                      subtitle: Text(
                        'Направление: ${requestData['category']}',
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MenteeDetailScreen(userId: requestData['userId']),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _removeMentee(String requestId) async {
    var currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      var trainerId = currentUser.uid;
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(trainerId)
          .collection('Requests')
          .doc(requestId)
          .update({'status': 'canceled'});
    }
  }
}

class MenteeDetailScreen extends StatefulWidget {
  final String userId;

  MenteeDetailScreen({required this.userId});

  @override
  _MenteeDetailScreenState createState() => _MenteeDetailScreenState();
}

class _MenteeDetailScreenState extends State<MenteeDetailScreen> {
  List<double> weightData = [];
  List<QueryDocumentSnapshot> trainings = [];
  User? currentUser;
  Map<String, int> dailyCalories = {'Завтрак': 0, 'Обед': 0, 'Ужин': 0};

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _loadWeightData();
    _loadDailyCalories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTrainings();
  }

  Future<void> _loadWeightData() async {
    final doc = await FirebaseFirestore.instance.collection('Users').doc(widget.userId).get();
    if (doc.exists) {
      setState(() {
        weightData = List<double>.from(doc.data()?['weightData'] ?? []);
      });
    }
  }

  Future<void> _loadTrainings() async {
    if (currentUser != null) {
      var trainingsSnapshot = await FirebaseFirestore.instance
          .collection('Trainings')
          .where('participants', arrayContains: widget.userId)
          .get();

      setState(() {
        trainings = trainingsSnapshot.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return data['title'] != 'Индивидуальная тренировка';
        }).toList();
      });
    }
  }

  Future<void> _loadDailyCalories() async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.userId)
        .collection('Meals')
        .where('timestamp', isGreaterThan: DateTime.now().subtract(Duration(days: 1)))
        .get();

    Map<String, int> caloriesByMealType = {'Завтрак': 0, 'Обед': 0, 'Ужин': 0};
    for (var doc in querySnapshot.docs) {
      var data = doc.data();
      String type = data['type'];
      int calories = data['calories'];
      caloriesByMealType[type] = (caloriesByMealType[type] ?? 0) + calories;
    }

    setState(() {
      dailyCalories = caloriesByMealType;
    });
  }

  Widget _buildWeightCard(String title, double weight) {
    var theme = Theme.of(context);
    var textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    var backgroundColor = theme.brightness == Brightness.dark ? Colors.black : Colors.white;
    return SizedBox(
      height: 100, // Установим фиксированную высоту для карточек
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300)),
              SizedBox(height: 10),
              Text('$weight кг', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionCard(BuildContext context) {
     var theme = Theme.of(context);
    var textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    var backgroundColor = theme.brightness == Brightness.dark ? Colors.black : Colors.white;


    int totalCalories = dailyCalories.values.reduce((a, b) => a + b);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NutritionScreen(userId: widget.userId),
          ),
        );
      },
      child: SizedBox(
        height: 115, // Установим фиксированную высоту для карточек
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: backgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Питание', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300)),
                SizedBox(height: 10),
                Text('ККАЛ: $totalCalories', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInviteCard(BuildContext context) {
    var theme = Theme.of(context);
    var textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    var backgroundColor = theme.brightness == Brightness.dark ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: () {
        _showTrainingSelectionDialog(context, widget.userId);
      },
      child: SizedBox(
        height: 115, // Установим фиксированную высоту для карточек
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: backgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 24, color: Colors.green), // Уменьшаем иконку
                SizedBox(height: 5),
                Text('Пригласить на', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                Text('тренировку', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeightChart() {
    var theme = Theme.of(context);
    var backgroundColor = theme.brightness == Brightness.dark ? Colors.black : Colors.white;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Вес', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            SizedBox(
              height: 100, // Задаем фиксированную высоту для LineChart
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false, border: Border.all(color: Color.fromARGB(31, 255, 255, 255))),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weightData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: Color.fromARGB(255, 6, 98, 77),
                      barWidth: 3,
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    var backgroundColor = theme.brightness == Brightness.dark ? Colors.black : Colors.white;

    double currentWeight = weightData.isNotEmpty ? weightData.last : 0.0;
    double initialWeight = weightData.isNotEmpty ? weightData.first : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Информация о подопечном'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Users').doc(widget.userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Нет данных о подопечном'));
          }
          
          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(userData['photoURL'] ?? 'URL_ЗАГЛУШКИ_ИЗОБРАЖЕНИЯ'),
                      radius: 30,
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${userData['name']} ${userData['surname']}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('Users').doc(currentUser!.uid).collection('Requests').doc(widget.userId).get(),
                          builder: (context, requestSnapshot) {
                            if (requestSnapshot.connectionState == ConnectionState.waiting) {
                              return Text('Загрузка...');
                            }
                            if (!requestSnapshot.hasData || !requestSnapshot.data!.exists) {
                              return Text('Категория не найдена');
                            }
                            var requestData = requestSnapshot.data!.data() as Map<String, dynamic>;
                            return Text(
                              'Направление: ${requestData['category']}',
                              style: TextStyle(color: Colors.grey),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildWeightCard('Текущий вес', currentWeight)),
                    SizedBox(width: 10),
                    Expanded(child: _buildWeightCard('Начальный вес', initialWeight)),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildNutritionCard(context)),
                    SizedBox(width: 10),
                    Expanded(child: _buildInviteCard(context)),
                  ],
                ),
                SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      SizedBox(height: 10),
                      _buildWeightChart(),
                      ListTile(
                        
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          
                          children: [
                            Text('Тренировки',style: TextStyle(fontWeight: FontWeight.w300, fontSize: 20,),),
                          ],
                        ),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('Trainings')
                            .where('participants', arrayContains: widget.userId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }

                          var trainings = snapshot.data!.docs;

                          if (trainings.isEmpty) {
                            return ListTile(
                              title: Text('Нет данных о тренировках'),
                            );
                          }

                          return Column(
                            children: trainings.map<Widget>((training) {
                              var trainingData = training.data() as Map<String, dynamic>;
                              // Исключаем отображение индивидуальных тренировок
                              if (trainingData['title'] == 'Индивидуальная тренировка') {
                                return Container();
                              }
                              return ListTile(
                                title: Text('Тренировка: ${trainingData['title']}'),
                                subtitle: Text(
                                  'Дата: ${DateFormat.yMMMd().format((trainingData['date'] as Timestamp).toDate())}',
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showTrainingSelectionDialog(BuildContext context, String userId) async {
    var currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      var trainerId = currentUser.uid;
      var trainingsSnapshot = await FirebaseFirestore.instance
          .collection('Trainings')
          .where('coachId', isEqualTo: trainerId)
          .get();

      showDialog(
        context: context,
        builder: (context) {
          
          return AlertDialog(
            title: Text('Выберите тренировку'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: trainingsSnapshot.docs.map((doc) {
                var trainingData = doc.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(trainingData['title']),
                  onTap: () {
                    _inviteToTraining(context, userId, trainingData['title'], doc.id);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          );
        },
      );
    }
  }

  Future<void> _inviteToTraining(BuildContext context, String userId, String trainingName, String trainingId) async {
    var currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final chatId = getChatId(currentUser.uid, userId);
      var message = 'Вас пригласили на тренировку: $trainingName';

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
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IndividualChatScreen(peerUserId: userId, userName: '', userImage: ''),
        ),
      );
    }
  }
}
