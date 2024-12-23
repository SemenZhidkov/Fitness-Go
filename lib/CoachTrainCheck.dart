import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class TrainDetailCheck extends StatelessWidget {
  final String trainingId;

  TrainDetailCheck({required this.trainingId});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    var backgroundColor = theme.brightness == Brightness.dark ? Colors.black : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text('Детали тренировки'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('Trainings').doc(trainingId).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Нет информации о тренировке. Она была отменена'));
          }

          var trainingData = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> participants = trainingData['participants'] ?? [];

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

              final GeoPoint geoPoint = trainingData['location'];
              final Point targetPoint = Point(
                latitude: geoPoint.latitude,
                longitude: geoPoint.longitude,
              );

              final PlacemarkMapObject placemark = PlacemarkMapObject(
                mapId: MapObjectId('placemark'),
                point: targetPoint,
                icon: PlacemarkIcon.single(
                  PlacemarkIconStyle(
                    image: BitmapDescriptor.fromAssetImage('assets/green.png'),
                    scale: 3,
                  ),
                ),
              );

              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Кружок аватарки тренера и его ФИО
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(coachData['photoURL']),
                                radius: 30,
                              ),
                              SizedBox(width: 10),
                              Text(
                                '${coachData['name']} ${coachData['surname']}',
                                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: textColor),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            trainingData['title'],
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            trainingData['description'],
                            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w200, color: textColor),
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
                                    color: textColor,
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
                                  onMapCreated: (YandexMapController controller) async {
                                    await Future.delayed(Duration(milliseconds: 100)); // Задержка перед перемещением камеры
                                    await controller.moveCamera(
                                      CameraUpdate.newCameraPosition(
                                        CameraPosition(target: targetPoint, zoom: 15),
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
                          SizedBox(height: 16.0),
                          Text(
                            'Участники',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          SizedBox(height: 10),
                          participants.isEmpty
                              ? Text('На тренировку еще никто не записался', style: TextStyle(color: textColor))
                              : StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('Users')
                                      .where(FieldPath.documentId, whereIn: participants)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Center(child: CircularProgressIndicator());
                                    }
                                    return Wrap(
                                      children: snapshot.data!.docs.map((doc) {
                                        var userData = doc.data() as Map<String, dynamic>;
                                        return Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: CircleAvatar(
                                            backgroundImage: userData['photoURL'] != null && userData['photoURL'].isNotEmpty
                                                ? NetworkImage(userData['photoURL'])
                                                : null,
                                            child: userData['photoURL'] == null || userData['photoURL'].isEmpty
                                                ? Icon(Icons.person, color: textColor)
                                                : null,
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                          SizedBox(height: 100.0), // Отступ, чтобы кнопка не накладывалась на контент
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 32,  // Отступ снизу
                    left: 16,
                    right: 16,
                    child: ElevatedButton(
                      onPressed: () => _deleteWorkout(trainingId, context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text('Отменить тренировку', style: TextStyle(color: Colors.white)),
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

  void _deleteWorkout(String trainingId, BuildContext context) async {
  try {
    await FirebaseFirestore.instance.collection('Trainings').doc(trainingId).delete();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Тренировка отменена')),
    );

    await Future.delayed(Duration(seconds: 1));

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка при отмене тренировки: $error')),
    );
  }
  }
}