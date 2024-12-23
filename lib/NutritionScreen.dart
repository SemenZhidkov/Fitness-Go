import 'package:fitnessgo/onChat_field_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class NutritionScreen extends StatefulWidget {
  final String userId;

  NutritionScreen({required this.userId});

  @override
  _NutritionScreenState createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _showCommentDialog(String mealType) async {
    String comment = '';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Комментарий для $mealType'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  onChanged: (value) {
                    comment = value;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Сохранить'),
              onPressed: () {
                _saveComment(mealType, comment);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveComment(String mealType, String comment) async {
    var trainerId = currentUser!.uid;
    var chatId = getChatId(trainerId, widget.userId);

    var message = {
      'text': 'Замечание по $mealType: $comment',
      'createdAt': FieldValue.serverTimestamp(),
      'userId': trainerId,
      'isRead': false,
      'mealType': mealType,
      'hasAttachment': true,
      'icon': 'restaurant_menu',
    };

    await FirebaseFirestore.instance.collection('chats/$chatId/messages').add(message);

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'lastMessage': 'Замечание по $mealType: $comment',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'users': [trainerId, widget.userId],
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Комментарий сохранен и отправлен в чат')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildCounter(Map<String, int> totals) {
    return Card(
      margin: EdgeInsets.all(8.0),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),),
      borderOnForeground: true,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Всего', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Калории: ${totals['calories'] ?? 0}'),
            Text('Белки: ${totals['proteins'] ?? 0} г'),
            Text('Жиры: ${totals['fats'] ?? 0} г'),
            Text('Углеводы: ${totals['carbs'] ?? 0} г'),
          ],
        ),
      ),
    );
  }

  Widget _buildMealItem(Map<String, dynamic> mealData) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mealData['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Калории: ${mealData['calories']}'),
            Text('Белки: ${mealData['proteins']} г'),
            Text('Жиры: ${mealData['fats']} г'),
            Text('Углеводы: ${mealData['carbs']} г'),
            SizedBox(height: 10),
            
          ],
        ),
      ),
    );
  }

  Widget _buildMealList(String mealType) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .collection('Meals')
          .where('type', isEqualTo: mealType)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка загрузки данных: ${snapshot.error}. Возможно, требуется создать индекс.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Нет данных'));
        }

        var meals = snapshot.data!.docs;
        Map<String, int> totals = {
          'calories': 0,
          'proteins': 0,
          'fats': 0,
          'carbs': 0,
        };

        meals.forEach((meal) {
          var data = meal.data() as Map<String, dynamic>;
          totals['calories'] = (totals['calories'] ?? 0) + (data['calories'] as num).toInt();
          totals['proteins'] = (totals['proteins'] ?? 0) + (data['proteins'] as num).toInt();
          totals['fats'] = (totals['fats'] ?? 0) + (data['fats'] as num).toInt();
          totals['carbs'] = (totals['carbs'] ?? 0) + (data['carbs'] as num).toInt();
        });

        return Column(
          children: [
            _buildCounter(totals),
            Expanded(
              child: ListView.builder(
                itemCount: meals.length,
                itemBuilder: (context, index) {
                  var mealData = meals[index].data() as Map<String, dynamic>;
                  return _buildMealItem(mealData);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Питание пользователя'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          indicatorColor: Colors.green ,
          tabs: [
            Tab(text: 'Завтрак'),
            Tab(text: 'Обед'),
            Tab(text: 'Ужин'),
          ],
        ),
        //backgroundColor: Colors.green, // Цвет AppBar и табов
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMealList('Завтрак'),
          _buildMealList('Обед'),
          _buildMealList('Ужин'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCommentDialog(_tabController.index == 0 ? 'Завтрак' : _tabController.index == 1 ? 'Обед' : 'Ужин'),
        child: Icon(Icons.comment),
        backgroundColor: Colors.green, // Зеленая кнопка
      ),
    );
  }
}
