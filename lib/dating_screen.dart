import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'models/user_model.dart';


final List<Map<String, dynamic>> fitnessCategories = [
  {'name': 'Йога', 'icon': 'assets/icons/yoga.svg', 'description': 'Йога - это комплекс духовных, психических и физических практик.'},
  {'name': 'Силовые', 'icon': 'assets/icons/sila.svg', 'description': 'Силовые тренировки направлены на развитие мышечной массы.'},
  {'name': 'Кардио', 'icon': 'assets/icons/cardio.svg', 'description': 'Кардио тренировки улучшают работу сердечно-сосудистой системы.'},
  {'name': 'Массонабор', 'icon': 'assets/icons/massnab.svg', 'description': 'Массонабор - тренировки для увеличения мышечной массы.'},
  {'name': 'Поддержание', 'icon': 'assets/icons/poderzh.svg', 'description': 'Тренировки для поддержания текущей физической формы.'},
  {'name': 'Похудение', 'icon': 'assets/icons/pohud.svg', 'description': 'Тренировки для снижения веса и улучшения здоровья.'},
  {'name': 'Правильное питание', 'icon': 'assets/icons/applepit.svg', 'description': 'Сбалансированное питание для здорового образа жизни.'},
  {'name': 'Интуитивное питание', 'icon': 'assets/icons/intlpit.svg', 'description': 'Интуитивное питание - подход к еде, основанный на ощущениях.'},
  {'name': 'Вегетарианец', 'icon': 'assets/icons/vegetar.svg', 'description': 'Вегетарианство - отказ от употребления мяса и рыбы.'},
];

class DatingScreen extends StatefulWidget {
  @override
  _DatingScreenState createState() => _DatingScreenState();
}

class _DatingScreenState extends State<DatingScreen> {
  List<UserModel> users = [];
  int currentIndex = 0;
  Set<String> viewedUserIds = {}; // Хранение идентификаторов просмотренных пользователей
  String selectedCategoryDescription = ''; // Описание выбранной категории
  double descriptionOpacity = 0.0; // Прозрачность описания
  UserService userService = UserService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    List<UserModel> loadedUsers = await userService.getUsers();

    // Исключаем уже просмотренных пользователей, пользователей без фото и тренеров
    loadedUsers.removeWhere((user) =>
      viewedUserIds.contains(user.id) ||
      user.photoURL.isEmpty ||
      user.role != 'Спортсмен'
    );

    setState(() {
      users = loadedUsers;
      currentIndex = 0; // Сброс текущего индекса при загрузке новых данных
    });
  }

  void _likeUser(UserModel user) async {
    await userService.likeUser(user.id);
    _markUserAsViewed(user);
  }

  void _skipUser(UserModel user) async {
    await userService.skipUser(user.id);
    _markUserAsViewed(user);
  }

  void _markUserAsViewed(UserModel user) {
    setState(() {
      viewedUserIds.add(user.id);
      users.remove(user);

      // Если текущий индекс выходит за пределы списка пользователей, сбрасываем его
      if (currentIndex >= users.length) {
        currentIndex = 0;
      }
    });
  }

  void _showCategoryDescription(String description) {
    setState(() {
      selectedCategoryDescription = description;
      descriptionOpacity = 1.0; // Показать описание
    });

    // Установить таймер для скрытия описания через 4 секунды
    Timer(Duration(seconds: 4), () {
      setState(() {
        descriptionOpacity = 0.0; // Скрыть описание
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.95;
    final cardHeight = MediaQuery.of(context).size.height * 0.80;

    if (users.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Знакомства'),
          actions: [
            IconButton(
              icon: Icon(Icons.favorite),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LikedUsersScreen()),
                );
              },
            ),
          ],
        ),
        body: Center(child: Text('Нет доступных пользователей')),
      );
    }

    UserModel user = users[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Знакомства'),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LikedUsersScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Dismissible(
                key: Key(user.id),
                direction: DismissDirection.horizontal,
                onDismissed: (direction) {
                  if (direction == DismissDirection.startToEnd) {
                    _likeUser(user);
                  } else {
                    _skipUser(user);
                  }
                },
                background: Container(
                  color: Colors.green,
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.favorite, color: Colors.white, size: 30),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.close, color: Colors.white, size: 30),
                ),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Container(
                    width: cardWidth, // Привязка ширины карточки к экрану
                    height: cardHeight, // Привязка высоты карточки к экрану
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                          child: Image.network(
                            user.photoURL,
                            width: cardWidth,
                            height: cardHeight * 0.6,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(
                                '${user.name} ${user.surname}, ${user.age}',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(user.role, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w200)),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: fitnessCategories
                                    .where((category) => user.choose[category['name']] == true)
                                    .map((category) => GestureDetector(
                                          onTap: () => _showCategoryDescription(category['description']),
                                          child: SvgPicture.asset(
                                            category['icon'],
                                            width: 30,
                                            height: 30,
                                            color: Colors.green, // Добавление зеленого цвета к иконкам
                                          ),
                                        ))
                                    .toList(),
                              ),
                              AnimatedOpacity(
                                opacity: descriptionOpacity,
                                duration: Duration(seconds: 1),
                                child: Text(
                                  selectedCategoryDescription,
                                  style: TextStyle(fontSize: 16, color: Colors.black54),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.red, size: 50),
                                onPressed: () => _skipUser(user),
                              ),
                              IconButton(
                                icon: Icon(Icons.favorite, color: Colors.green, size: 50),
                                onPressed: () => _likeUser(user),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LikedUsersScreen extends StatelessWidget {
  final UserService userService = UserService();

  Future<void> _addFriend(UserModel user) async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final currentUserRef = FirebaseFirestore.instance.collection('Users').doc(currentUser.uid);
    final friendRef = FirebaseFirestore.instance.collection('Users').doc(user.id);

    // Add friend to current user's friend list
    await currentUserRef.collection('friends').doc(user.id).set({
      'userId': user.id,
      'name': user.name,
      'photoURL': user.photoURL,
      'addedAt': FieldValue.serverTimestamp(),
    });

    // Add current user to friend's friend list
    final currentUserData = await currentUserRef.get();
    await friendRef.collection('friends').doc(currentUser.uid).set({
      'userId': currentUser.uid,
      'name': currentUserData['name'],
      'photoURL': currentUserData['photoURL'],
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Симпатии')),
      body: FutureBuilder<List<UserModel>>(
        future: userService.getUsersWhoLikedMe(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Пока что здесь пусто...'));
          }

          final likedUsers = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 0.6,
              ),
              itemCount: likedUsers.length,
              itemBuilder: (context, index) {
                final user = likedUsers[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                        child: Image.network(
                          user.photoURL,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.name} ${user.surname}, ${user.age}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 5),
                            Text(user.role, style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red, size: 24),
                              onPressed: () {
                                // Добавьте логику для пропуска
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.favorite, color: Colors.green, size: 24),
                              onPressed: () async {
                                await _addFriend(user);
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
        },
      ),
    );
  }
}
