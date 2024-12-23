import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrainersListScreen extends StatelessWidget {
  final String placeholderImageUrl = 'URL_ЗАГЛУШКИ_ИЗОБРАЖЕНИЯ'; // URL заглушки из Firebase Storage

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Найти тренера'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Users').where('role', isEqualTo: 'Тренер').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Нет доступных тренеров'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var trainerData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              var trainerId = snapshot.data!.docs[index].id;
              var photoUrl = trainerData['photoURL'] ?? placeholderImageUrl;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(photoUrl),
                  radius: 30,
                ),
                title: Text('${trainerData['name']} ${trainerData['surname']}'),
                subtitle: RatingBarIndicator(
                  rating: trainerData['rating']?.toDouble() ?? 0,
                  itemBuilder: (context, index) => Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 20.0,
                  direction: Axis.horizontal,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrainerProfileScreen(trainerId: trainerId),
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
}

class TrainerProfileScreen extends StatefulWidget {
  final String trainerId;

  TrainerProfileScreen({required this.trainerId});

  @override
  _TrainerProfileScreenState createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends State<TrainerProfileScreen> {
  bool isRequestSent = false;
  String selectedCategory = '';
  Map<String, dynamic> choose = {};

  @override
  void initState() {
    super.initState();
    _checkIfRequestSent();
  }

  Future<void> _checkIfRequestSent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.trainerId)
          .collection('Requests')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      setState(() {
        isRequestSent = querySnapshot.docs.isNotEmpty;
      });
    }
  }

  Future<void> _cancelRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.trainerId)
          .collection('Requests')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      setState(() {
        isRequestSent = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Запрос отменен.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль тренера'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Users').doc(widget.trainerId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Нет данных о тренере'));
          }

          var trainerData = snapshot.data!.data() as Map<String, dynamic>;
          var photoUrl = trainerData['photoURL'] ?? 'URL_ЗАГЛУШКИ_ИЗОБРАЖЕНИЯ';
          choose = trainerData['choose'] as Map<String, dynamic>;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('TrainersInfo').doc(widget.trainerId).get(),
            builder: (context, trainerInfoSnapshot) {
              if (trainerInfoSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              var trainerInfo = trainerInfoSnapshot.data?.data() as Map<String, dynamic>? ?? {};

              return Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Center(
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(photoUrl),
                              radius: 50,
                            ),
                          ),
                          SizedBox(height: 16.0),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  '${trainerData['name']} ${trainerData['surname']}',
                                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8.0),
                                RatingBarIndicator(
                                  rating: trainerData['rating']?.toDouble() ?? 0,
                                  itemBuilder: (context, index) => Icon(
                                    Icons.star,
                                    color: Colors.green,
                                  ),
                                  itemCount: 5,
                                  itemSize: 24.0,
                                  direction: Axis.horizontal,
                                ),
                                  Text(
                                  '${(trainerData['rating']?.toDouble() ?? 0.0).toStringAsFixed(1)}',
                                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                                ),

                              ],
                            ),
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            'Направления',
                            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8.0),
                          Wrap(
                            spacing: 10.0,
                            runSpacing: 10.0,
                            children: List<Widget>.generate(
                              choose.length,
                              (index) {
                                String category = choose.keys.elementAt(index);
                                bool isSelected = choose[category];
                                if (isSelected) {
                                  return SvgPicture.asset(
                                    getIconPath(category),
                                    width: 50,
                                    height: 50,
                                    color: Colors.green,
                                  );
                                }
                                return Container();
                              },
                            ),
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            'Анкета тренера',
                            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8.0),
                          buildInfoBlock('Образование', trainerInfo['education']),
                          SizedBox(height: 8.0),
                          buildInfoBlock('Достижения', trainerInfo['achievements']),
                          SizedBox(height: 8.0),
                          buildInfoBlock('Специализация', trainerInfo['specialization']),
                          SizedBox(height: 16.0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TrainerReviewsScreen(trainerId: widget.trainerId),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green,
                            side: BorderSide(color: Colors.green, width: 2),
                            minimumSize: Size(double.infinity, 50), // Set the button size
                            padding: EdgeInsets.all(10),
                          ),
                          child: Text(
                            'Посмотреть отзывы',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        SizedBox(height: 15.0),
                        isRequestSent
                            ? ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Отменить заявку?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: Text('Отмена', style: TextStyle(color: Colors.red)),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              _cancelRequest();
                                            },
                                            child: Text('Да', style: TextStyle(color: Colors.green)),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.green,
                                  side: BorderSide(color: Colors.green, width: 2),
                                  minimumSize: Size(double.infinity, 50), // Set the button size
                                  padding: EdgeInsets.all(10),
                                ),
                                child: Text(
                                  'Заявка оставлена',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _showCategorySelectionScreen,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size(double.infinity, 50), // Set the button size
                                  padding: EdgeInsets.all(10),
                                ),
                                child: Text('Привязаться'),
                              ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget buildInfoBlock(String title, String? content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              content ?? 'Не указано',
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategorySelectionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategorySelectionScreen(
          trainerId: widget.trainerId,
          onCategorySelected: (category, letter) {
            setState(() {
              selectedCategory = category;
            });
            _submitRequest(letter);
          },
        ),
      ),
    );
  }

  Future<void> _submitRequest(String letter) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final request = {
        'userId': user.uid,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'category': selectedCategory,
        'letter': letter,
      };

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.trainerId)
          .collection('Requests')
          .add(request);

      setState(() {
        isRequestSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Запрос отправлен!')),
      );
    }
  }

  String getIconPath(String categoryName) {
    switch (categoryName) {
      case 'Вегетарианец':
        return 'assets/icons/vegetar.svg';
      case 'Интуитивное питание':
        return 'assets/icons/intlpit.svg';
      case 'Йога':
        return 'assets/icons/yoga.svg';
      case 'Кардио':
        return 'assets/icons/cardio.svg';
      case 'Массонабор':
        return 'assets/icons/massnab.svg';
      case 'Поддержание':
        return 'assets/icons/poderzh.svg';
      case 'Похудение':
        return 'assets/icons/pohud.svg';
      case 'Правильное питание':
        return 'assets/icons/applepit.svg';
      case 'Силовые':
        return 'assets/icons/sila.svg';
      default:
        return 'assets/icons/sila.svg';
    }
  }
}

class CategorySelectionScreen extends StatefulWidget {
  final String trainerId;
  final void Function(String category, String letter) onCategorySelected;

  CategorySelectionScreen({required this.trainerId, required this.onCategorySelected});

  @override
  _CategorySelectionScreenState createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  String selectedCategory = '';
  final TextEditingController _letterController = TextEditingController();
  final PageController _pageController = PageController(viewportFraction: 0.3);
  Map<String, dynamic> choose = {};

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final doc = await FirebaseFirestore.instance.collection('Users').doc(widget.trainerId).get();
    setState(() {
      choose = doc.data()!['choose'] as Map<String, dynamic>;
      if (choose.isNotEmpty) {
        selectedCategory = choose.keys.firstWhere((key) => choose[key] == true, orElse: () => '');
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _letterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = choose.keys.where((key) => choose[key] == true).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Выберите направление'),
      ),
      body: choose.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 100,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: categories.length,
                      onPageChanged: (index) {
                        setState(() {
                          selectedCategory = categories[index];
                        });
                      },
                      itemBuilder: (context, index) {
                        String category = categories[index];
                        bool isSelected = category == selectedCategory;

                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 8.0),
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.green : Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: ColorFiltered(
                              colorFilter: isSelected
                                  ? ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                                  : ColorFilter.mode(Colors.white.withOpacity(0.7), BlendMode.modulate),
                              child: SvgPicture.asset(
                                getIconPath(category),
                                width: 50,
                                height: 50,
                                color: isSelected ? Colors.white : Colors.green,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Container(
                    height: 85, // Статичный размер для описания
                    child: SingleChildScrollView(
                      child: _getCategoryDescriptionWidget(selectedCategory),
                    ),
                  ),
                  SizedBox(height: 26.0),
                  TextField(
                    controller: _letterController,
                    decoration: InputDecoration(
                      labelText: 'Опишите ваши задачи',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 10.0),
                ],
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(26.0),
        child: ElevatedButton(
          
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Подтверждение запроса'),
                  content: Text(
                    'При одобрении заявки, тренеру станет доступен просмотр информации:\n'
                    '- Ваше питание\n'
                    '- Ваша активность\n'
                    '- Ваши тренировки\n'
                    'Продолжить?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Отмена', style: TextStyle(color: Colors.red)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onCategorySelected(selectedCategory, _letterController.text);
                        Navigator.pop(context);
                      },
                      child: Text('Продолжить', style: TextStyle(color: Colors.green)),
                    ),
                  ],
                );
              },
            );
          },
          child: Text('Отправить запрос'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.all(15.0),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50),
            side: BorderSide(color: Colors.green, width: 2),
          ),
        ),
      ),
    );
  }

  String getIconPath(String categoryName) {
    switch (categoryName) {
      case 'Вегетарианец':
        return 'assets/icons/vegetar.svg';
      case 'Интуитивное питание':
        return 'assets/icons/intlpit.svg';
      case 'Йога':
        return 'assets/icons/yoga.svg';
      case 'Кардио':
        return 'assets/icons/cardio.svg';
      case 'Массонабор':
        return 'assets/icons/massnab.svg';
      case 'Поддержание':
        return 'assets/icons/poderzh.svg';
      case 'Похудение':
        return 'assets/icons/pohud.svg';
      case 'Правильное питание':
        return 'assets/icons/applepit.svg';
      case 'Силовые':
        return 'assets/icons/sila.svg';
      default:
        return 'assets/icons/sila.svg';
    }
  }

  Widget _getCategoryDescriptionWidget(String category) {
    String title;
    String description;

    switch (category) {
      case 'Вегетарианец':
        title = 'Вегетарианец';
        description = 'Вегетарианство - отказ от употребления мяса и рыбы';
        break;
      case 'Интуитивное питание':
        title = 'Интуитивное питание';
        description = 'Интуитивное питание - подход к еде, основанный на ощущениях';
        break;
      case 'Йога':
        title = 'Йога';
        description = 'Йога - это комплекс духовных, психических и физических практик';
        break;
      case 'Кардио':
        title = 'Кардио';
        description = 'Кардио тренировки улучшают работу сердечно-сосудистой системы';
        break;
      case 'Массонабор':
        title = 'Массонабор';
        description = 'Массонабор - тренировки для увеличения мышечной массы';
        break;
      case 'Поддержание':
        title = 'Поддержание';
        description = 'Поддержание - Тренировки для поддержания текущей физической формы';
        break;
      case 'Похудение':
        title = 'Похудение';
        description = 'Похудение - Тренировки для снижения веса и улучшения здоровья';
        break;
      case 'Правильное питание':
        title = 'Правильное питание';
        description = 'Сбалансированное питание для здорового образа жизни';
        break;
      case 'Силовые':
        title = 'Силовые';
        description = 'Силовые тренировки направлены на развитие мышечной массы';
        break;
      default:
        title = 'Описание не доступно';
        description = '';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            title,
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 8.0),
        Text(
          description,
          style: TextStyle(fontSize: 16.0),
        ),
      ],
    );
  }
}

class TrainerReviewsScreen extends StatefulWidget {
  final String trainerId;

  TrainerReviewsScreen({required this.trainerId});

  @override
  _TrainerReviewsScreenState createState() => _TrainerReviewsScreenState();
}

class _TrainerReviewsScreenState extends State<TrainerReviewsScreen> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 3.0;

  Future<void> _submitReview(BuildContext dialogContext) async {
  if (_reviewController.text.isEmpty) {
    ScaffoldMessenger.of(dialogContext).showSnackBar(
      SnackBar(content: Text('Распишите ваш отзыв!')),
    );
    return;
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(dialogContext).showSnackBar(
      SnackBar(content: Text('You must be logged in to leave a review.')),
    );
    return;
  }

  final review = {
    'userId': user.uid,
    'rating': _rating,
    'text': _reviewController.text,
    'timestamp': FieldValue.serverTimestamp(),
  };

  await FirebaseFirestore.instance
      .collection('Users')
      .doc(widget.trainerId)
      .collection('Reviews')
      .add(review);

  _reviewController.clear();
  Navigator.of(dialogContext).pop();

  // Обновляем рейтинг тренера
  _updateTrainerRating(widget.trainerId);

  Future.delayed(Duration(milliseconds: 300), () {
    ScaffoldMessenger.of(dialogContext).showSnackBar(
      SnackBar(content: Text('Отзыв добавлен!')),
    );
  });
}

Future<void> _updateTrainerRating(String trainerId) async {
  final reviewsSnapshot = await FirebaseFirestore.instance
      .collection('Users')
      .doc(trainerId)
      .collection('Reviews')
      .get();

  if (reviewsSnapshot.docs.isNotEmpty) {
    double totalRating = 0.0;
    for (var doc in reviewsSnapshot.docs) {
      totalRating += doc['rating'];
    }
    double newRating = totalRating / reviewsSnapshot.docs.length;

    // Обновляем поле рейтинга у тренера
    await FirebaseFirestore.instance.collection('Users').doc(trainerId).update({
      'rating': newRating,
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Отзывы о тренере'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(widget.trainerId)
                  .collection('Reviews')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final reviews = snapshot.data!.docs;

                return Container(
                  height: 200,  // Пример фиксированной высоты
                  child: ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return ListTile(
                      leading: Icon(Icons.star, color: Colors.green),
                      title: Text(review['text']),
                      subtitle: Text('Оценка: ${review['rating']}'),
                    );
                  },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), // Set the button size
                padding: EdgeInsets.all(10),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Container(
                      height: 250, // Увеличиваем высоту диалога
                      child: Column(
                        children: [
                          RatingBar.builder(
                            initialRating: 3,
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: true,
                            itemCount: 5,
                            itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                            itemBuilder: (context, _) => Icon(
                              Icons.star,
                              color: Colors.green,
                            ),
                            onRatingUpdate: (rating) {
                              setState(() {
                                _rating = rating;
                              });
                            },
                          ),
                           SizedBox(height: 20),
                          TextField(
                            controller: _reviewController,
                            decoration: InputDecoration(
                              labelText: 'Ваш отзыв',
                            filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                            ),
                            maxLines: 7,
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.2, // 30% ширины экрана
                            child: IconButton(
                              
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(Icons.close, color: Colors.redAccent),
                              iconSize: 24,
                              color: Colors.red,
                              padding: EdgeInsets.all(5.0),
                              splashColor: Colors.redAccent,
                              //highlightColor: Colors.redAccent,
                            ),

                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.4, // 70% ширины экрана
                            child: ElevatedButton(
                              onPressed:() => _submitReview(context),
                              child: Text('Готово',
                              style: TextStyle(fontWeight: FontWeight.w400 ),
                              ),
                              style: ElevatedButton.styleFrom(
                                
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white, // Зеленоватый цвет кнопки
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              child: Text('Оставить отзыв'),
            ),
          ),
        ],
      ),
    );
  }
}
