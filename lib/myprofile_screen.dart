import 'dart:io';

import 'package:fitnessgo/stat_screnn.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';
import 'dart:async';
import 'food_details_screen.dart';
import 'service_stream.dart';
import 'package:health/health.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

enum AppState {
  DATA_NOT_FETCHED,
  FETCHING_DATA,
  DATA_READY,
  NO_DATA,
  AUTHORIZED,
  AUTH_NOT_GRANTED,
  DATA_ADDED,
  DATA_DELETED,
  DATA_NOT_ADDED,
  DATA_NOT_DELETED,
  STEPS_READY,
  HEALTH_CONNECT_STATUS,
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<HealthDataPoint> _healthDataList = [];
  AppState _state = AppState.DATA_NOT_FETCHED;
  User? currentUser;
  double totalWater = 0;
  List<double> weightData = [];
  String _photoUrl = '';
  String _fullName = '';
 
 
  
  int _nofSteps = 0;
  Timer? _timer;
  final MealService mealService = MealService();
  
  static final types = [
    HealthDataType.STEPS,
    HealthDataType.AUDIOGRAM
   ];
   List<HealthDataAccess> get permissions =>
      types.map((e) => HealthDataAccess.READ).toList();
  

  @override
  void initState() {
    Health().configure(useHealthConnectIfAvailable: true);
    super.initState();
    _loadUserProfile();
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _loadData();
      _checkAndFetchStepData();
    }
  }
  //Проверка наличия googleHealth на устройстве
  Future<void> installHealthConnect() async {
    await Health().installHealthConnect();
  }
  //Авторизация в googleHealth
  Future<void> authorize() async {
    await Permission.activityRecognition.request();
    await Permission.location.request();

    // Check if we have health permissions
    bool? hasPermissions =
        await Health().hasPermissions(types, permissions: permissions);
      hasPermissions = false;
      bool authorized = false;
      if (!hasPermissions) {
        // requesting access to the data types before reading them
        try {
          authorized = await Health()
              .requestAuthorization(types, permissions: permissions);
        } catch (error) {
          debugPrint("Exception in authorize: $error");
        }
      }
      setState(() => _state =
          (authorized) ? AppState.AUTHORIZED : AppState.AUTH_NOT_GRANTED);
    }
    Future<void> getHealthConnectSdkStatus() async {
    assert(Platform.isAndroid, "This is only available on Android");

    final status = await Health().getHealthConnectSdkStatus();

    setState(() {
      _state = AppState.HEALTH_CONNECT_STATUS;
    });
  }
  
  Future<void> _loadData() async {
    await _loadWaterData();
    await _loadWeightData();
  }
  Future<void> fetchStepData() async {
    int? steps;

    // get steps for today (i.e., since midnight)
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    bool stepsPermission =
        await Health().hasPermissions([HealthDataType.STEPS]) ?? false;
    if (!stepsPermission) {
      stepsPermission =
          await Health().requestAuthorization([HealthDataType.STEPS]);
    }

    if (stepsPermission) {
      try {
        steps = await Health().getTotalStepsInInterval(midnight, now);
      } catch (error) {
        debugPrint("Exception in getTotalStepsInInterval: $error");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Total number of steps: $steps, nofsteps $_nofSteps')),
      );
      debugPrint('Total number of steps: $steps');

      setState(() {
        _nofSteps = (steps == null) ? 0 : steps;
        _state = (steps == null) ? AppState.NO_DATA : AppState.STEPS_READY;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastStepFetch', now.millisecondsSinceEpoch);
    } else {
      debugPrint("Authorization not granted - error in authorization");
      setState(() => _state = AppState.DATA_NOT_FETCHED);
    }
  }

  Future<void> _checkAndFetchStepData() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetch = prefs.getInt('lastStepFetch') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastFetch > 3600000) {
      await fetchStepData();
    }
  }
  

  

  Future<void> _loadWaterData() async {
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance.collection('Users').doc(currentUser!.uid).get();
    if (doc.exists) {
      final data = doc.data();
      final waterTimestamp = data?['waterTimestamp']?.toDate() ?? DateTime.now();
      final currentTime = DateTime.now();

      if (_isSameDay(waterTimestamp, currentTime)) {
        setState(() {
          totalWater = data?['totalWater'] ?? 0;
        });
      } else {
        setState(() {
          totalWater = 0;
        });
      }
    }
  }

  Future<void> _loadWeightData() async {
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance.collection('Users').doc(currentUser!.uid).get();
    if (doc.exists) {
      setState(() {
        weightData = List<double>.from(doc.data()?['weightData'] ?? []);
      });
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  @override
  void dispose() {
    _timer?.cancel(); // Отменяем таймер при уничтожении виджета
    super.dispose();
  }

  

  Future<void> _loadUserProfile() async {
    try {
      // Предположим, что пользователь уже аутентифицирован
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Получение документа пользователя из Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();

      if (userDoc.exists) {
        setState(() {
          // Используйте название полей как в вашей базе данных
          _photoUrl = userDoc['photoURL'] ?? '';
          _fullName = "${userDoc['name'] ?? ''} ${userDoc['surname'] ?? ''}";
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      // Отобразить сообщение об ошибке, если требуется
    }
  }

  


  

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.themeOf(context).data;
    return ThemeConsumer(
    child: Scaffold(
      body: ListView(
        children: <Widget>[
          _buildProfileSection(context, theme),
          _buildSummarySection(context, theme),
          _buildMealsSection(context, theme),
          _buildCaloriesSection(context, theme), // Добавляем новый раздел
        ],
      ),
    )
    );
  }

  Widget _buildProfileSection(BuildContext context, ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(top: 38, bottom: 24, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          CircleAvatar(
            radius: 35,
            backgroundImage: _photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null,
            child: _photoUrl.isEmpty ? Icon(Icons.camera_alt, size: 50) : null,
          ),
          Text(_fullName, style: TextStyle(fontSize: 24, color: theme.textTheme.bodyLarge?.color)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, ThemeData theme) {
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
        SizedBox(height: 4),
        Text(value, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context, ThemeData theme) {
    return ThemeConsumer(
      child: InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => StatScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(13.0),
        margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color.fromARGB(255, 6, 98, 77),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 4,
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              _buildSummaryCard(context, 'assets/icons/water.svg', 'Вода', mealService.getWaterStream(), 'Л',),
              _buildSummaryCard(context, 'assets/icons/steps.svg', 'Шаги', Stream.value(_nofSteps), ''),
              _buildSummaryCard(context, 'assets/icons/weightloc.svg', 'Вес', mealService.getWeightStream(), 'Кг'),
              //TextButton(onPressed: fetchStepData, child: Text("Fetch Step Data",
                          //style: TextStyle(color: Colors.white)),
                      //style: ButtonStyle(
                          //backgroundColor:
                              //MaterialStatePropertyAll(Colors.blue))),
            ],
          ),
        ),
        
      ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String iconPath, String title, Stream<dynamic> valueStream, String text, ) {
    return Expanded(
      child: StreamBuilder<dynamic>(
        stream: valueStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SvgPicture.asset(iconPath, width: 30, height: 30),
                SizedBox(height: 8),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text('Загрузка...', style: Theme.of(context).textTheme.titleSmall),
              ],
            );
          }
          String value = '';
          if (snapshot.data is double) {
            value = (snapshot.data as double).toStringAsFixed(1);
          } else if (snapshot.data is String) {
            value = snapshot.data as String;
          } else if (snapshot.data is int) {
            value = snapshot.data.toString();
          } else if (snapshot.data is List<double> && (snapshot.data as List<double>).isNotEmpty) {
            value = (snapshot.data as List<double>).last.toStringAsFixed(0);
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SvgPicture.asset(iconPath, width: 30, height: 30),
              SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              Text(value, style: Theme.of(context).textTheme.titleSmall),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMealsSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Ваше питание',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: theme.textTheme.bodyLarge?.color),
          ),
         
        ),
        SizedBox(height: 16),
        Row(
          
          
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildMealCard(context, 'Завтрак', theme),
            _buildMealCard(context, 'Обед', theme),
            _buildMealCard(context, 'Ужин', theme),
          ],
        ),
      ],
    );
  }

  Widget _buildMealCard(BuildContext context, String mealName, ThemeData theme) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FoodDetailsScreen(mealType: mealName)),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: Color.fromARGB(255, 6, 98, 77),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(mealName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaloriesSection(BuildContext context, ThemeData theme) {
    return StreamBuilder<Map<String, int>>(
      stream: mealService.getCaloriesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return Text('Нет данных');
        }

        final caloriesByMealType = snapshot.data!;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
            color: Color.fromARGB(255, 6, 98, 77),
            width: 2.0,
          ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Калории за сегодня', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300)),
              SizedBox(height: 16),
              _buildCaloriesRow('Завтрак', caloriesByMealType['Завтрак'] ?? 0),
              _buildCaloriesRow('Обед', caloriesByMealType['Обед'] ?? 0),
              _buildCaloriesRow('Ужин', caloriesByMealType['Ужин'] ?? 0),
            ],
          ),
        );
      },
    );
    
  }

  Widget _buildCaloriesRow(String mealType, int calories) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(mealType, style: TextStyle(fontSize: 18)),
        Text('$calories ккал', style: TextStyle(fontSize: 18)),
      ],
      
    );
    
  }
  
}
