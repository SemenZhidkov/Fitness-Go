import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final String workoutId;

  WorkoutDetailScreen({required this.workoutId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Детали тренировки'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('Trainings').doc(workoutId).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No data found for this training'));
          }

          var trainingData = snapshot.data!.data() as Map<String, dynamic>;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('Users').doc(trainingData['coachId']).get(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> coachSnapshot) {
              if (coachSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (coachSnapshot.hasError) {
                return Center(child: Text('Error: ${coachSnapshot.error}'));
              }

              if (!coachSnapshot.hasData || !coachSnapshot.data!.exists) {
                return Center(child: Text('No data found for this coach'));
              }

              var coachData = coachSnapshot.data!.data() as Map<String, dynamic>;

              final PlacemarkMapObject placemark = PlacemarkMapObject(
                mapId: MapObjectId('placemark'),
                point: Point(latitude: trainingData['location'].latitude, longitude: trainingData['location'].longitude),
                icon: PlacemarkIcon.single(
                  PlacemarkIconStyle(image: BitmapDescriptor.fromAssetImage('assets/green.png'), scale: 3),
                ),
              );

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(coachData['photoURL']),
                                radius: 30,
                              ),
                              SizedBox(width: 10),
                              Text(
                                '${coachData['name']} ${coachData['surname']}',
                                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            trainingData['title'],
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            trainingData['description'],
                            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w200,),
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            'Категории',
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Wrap(
                            spacing: 10.0,
                            children: List<Widget>.generate(
                              trainingData['categories'].length,
                              (index) {
                                return SvgPicture.asset(
                                  getIconPath(trainingData['categories'][index]),
                                  width: 40,
                                  height: 40,
                                  color: Colors.green,
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Image.asset(
                                trainingData['centerLogo'],
                                height: 50.0,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  trainingData['centerAddress'],
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w200,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.0),
                          Container(
                            height: 300.0,
                             child: FutureBuilder(
                          future: Future.delayed(Duration(milliseconds: 100)), // Задержка для инициализации карты
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            return YandexMap(
                              tiltGesturesEnabled: false,
                              zoomGesturesEnabled: true,
                              rotateGesturesEnabled: true,
                              scrollGesturesEnabled: false,
                              mapObjects: [placemark],
                              onMapCreated: (YandexMapController controller)async {
                                 await Future.delayed(Duration(milliseconds: 100));
                                controller.moveCamera(
                                  
                                  CameraUpdate.newCameraPosition(
                                    CameraPosition(target: placemark.point, zoom: 16),
                                  ),
                                  animation: const MapAnimation(
                                  type: MapAnimationType.linear,
                                  duration: 0.9,
                               ),
                                );
                              },
                            );
                          },
                        ),
                        ),
                        ],
                      ),
                    ),
                  ),
                  
                  Container(
                    padding: EdgeInsets.only(bottom: 25.0, left: 25.0, right: 25.0, top: 10.0),
                   
                    
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Свободных мест: ${(trainingData['capacity'] - (trainingData['participants']?.length ?? 0)).toString()}',
                          style: TextStyle(fontSize: 18.0),
                        ),
                        ElevatedButton(
                          onPressed: () => _registerForWorkout(trainingData, context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: Size(130, 50),
                          ),
                          child: Text('Записаться'),
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

  void _registerForWorkout(Map<String, dynamic> trainingData, BuildContext context) async {
    var currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Проверка на максимальное количество участников
      if ((trainingData['participants']?.length ?? 0) >= trainingData['capacity']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Максимальное количество участников достигнуто')),
        );
        return;
      }

      // Проверка на дублирование записи
      bool alreadyRegistered = (trainingData['participants'] ?? []).contains(currentUser.uid);
      if (alreadyRegistered) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Вы уже записаны на эту тренировку')),
          
        );
        Navigator.pop(context); 
        
      }

      // Запись пользователя на тренировку
      FirebaseFirestore.instance.collection('Trainings').doc(workoutId).update({
        'participants': FieldValue.arrayUnion([currentUser.uid])
      }).then((value) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Вы успешно записались на тренировку')),
        );
         Navigator.pop(context);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при записи на тренировку: $error')),
        );
      });
    }
  }

  String getIconPath(String categoryName) {
    switch (categoryName) {
      case 'Йога':
        return 'assets/icons/yoga.svg';
      case 'Силовые':
        return 'assets/icons/sila.svg';
      case 'Кардио':
        return 'assets/icons/cardio.svg';
      case 'Массонабор':
        return 'assets/icons/massnab.svg';
      case 'Поддержание':
        return 'assets/icons/poderzh.svg';
      case 'Похудение':
        return 'assets/icons/pohud.svg';
      case 'ПП':
        return 'assets/icons/applepit.svg';
      case 'Инт. питание':
        return 'assets/icons/intlpit.svg';
      case 'Вегетарианец':
        return 'assets/icons/vegetar.svg';
      default:
        return 'assets/icons/default.svg';
    }
  }
}
