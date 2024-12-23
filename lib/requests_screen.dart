import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'onChat_field_screen.dart'; // Импортируем экран чата

class TrainerRequestsScreen extends StatefulWidget {
  @override
  _TrainerRequestsScreenState createState() => _TrainerRequestsScreenState();
}

class _TrainerRequestsScreenState extends State<TrainerRequestsScreen> {
  User? currentUser;
  late String trainerId;
  String selectedFilter = 'Все';
  final String placeholderImageUrl = 'URL_ЗАГЛУШКИ_ИЗОБРАЖЕНИЯ'; // URL заглушки изображения
  final List<String> approvedRequests = [];

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      trainerId = currentUser!.uid;
    } else {
      // Обработка случая, если пользователь не авторизован
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Запросы пользователей'),
        ),
        body: Center(child: Text('Пользователь не авторизован')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Запросы пользователей'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              setState(() {
                selectedFilter = result;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Все',
                child: Text('Все'),
              ),
              const PopupMenuItem<String>(
                value: 'Сегодня',
                child: Text('Сегодня'),
              ),
              const PopupMenuItem<String>(
                value: 'На этой неделе',
                child: Text('На этой неделе'),
              ),
              const PopupMenuItem<String>(
                value: 'В этом месяце',
                child: Text('В этом месяце'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getFilteredStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Нет запросов от пользователей'));
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

                  var userData = userSnapshot.data!.data() as Map<String, dynamic>?;

                  if (userData == null) {
                    return ListTile(
                      title: Text('Неизвестный пользователь'),
                    );
                  }

                  bool isApproved = approvedRequests.contains(requestId);

                  return AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    color: isApproved ? Colors.green.withOpacity(0.1) : Colors.transparent,
                    child: ListTile(
                      title: Text('${userData['name'] ?? 'Неизвестный'} ${userData['surname'] ?? 'пользователь'}'),
                      subtitle: Text('Направление: ${requestData['category']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isApproved)
                            IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed: () => _approveRequest(requestId),
                            ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.red),
                            onPressed: () => _rejectRequest(requestId),
                          ),
                        ],
                      ),
                      onTap: () {
                        _showRequestDialog(requestData['userId'], requestData['letter']);
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

  Stream<QuerySnapshot> _getFilteredStream() {
    var query = FirebaseFirestore.instance
        .collection('Users')
        .doc(trainerId)
        .collection('Requests')
        .where('status', isEqualTo: 'pending');

    switch (selectedFilter) {
      case 'Сегодня':
        var startOfDay = DateTime.now().toUtc().subtract(Duration(
            hours: DateTime.now().toUtc().hour,
            minutes: DateTime.now().toUtc().minute,
            seconds: DateTime.now().toUtc().second));
        query = query.where('timestamp', isGreaterThanOrEqualTo: startOfDay);
        break;
      case 'На этой неделе':
        var startOfWeek = DateTime.now().toUtc().subtract(Duration(days: DateTime.now().weekday - 1));
        startOfWeek = startOfWeek.subtract(Duration(
            hours: startOfWeek.hour,
            minutes: startOfWeek.minute,
            seconds: startOfWeek.second));
        query = query.where('timestamp', isGreaterThanOrEqualTo: startOfWeek);
        break;
      case 'В этом месяце':
        var startOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
        query = query.where('timestamp', isGreaterThanOrEqualTo: startOfMonth);
        break;
      default:
        // Нет дополнительной фильтрации для "Все"
        break;
    }

    return query.snapshots();
  }

  Future<void> _approveRequest(String requestId) async {
    setState(() {
      approvedRequests.add(requestId);
    });
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(trainerId)
        .collection('Requests')
        .doc(requestId)
        .update({'status': 'approved'});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Заявка принята, пользователь добавлен в список подопечных')),
    );

    await Future.delayed(Duration(seconds: 1));

    setState(() {
      approvedRequests.remove(requestId);
    });
  }

  Future<void> _rejectRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(trainerId)
        .collection('Requests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }

  void _showRequestDialog(String userId, String letter) async {
    var userDoc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    var userData = userDoc.data() as Map<String, dynamic>?;
    var userName = userData?['name'] ?? 'Неизвестный пользователь';
    var userImage = userData?['photoURL'] ?? placeholderImageUrl;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Сопроводительное письмо'),
          content: Text(letter),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Закрыть'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IndividualChatScreen(
                      peerUserId: userId,
                      userName: userName,
                      userImage: userImage,
                    ),
                  ),
                );
              },
              child: Text('Связаться'),
            ),
          ],
        );
      },
    );
  }
}
