import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'meal.dart';

class MealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Meal>> getMeals() {
    return _firestore
        .collection('Users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('Meals')
        .where('timestamp', isGreaterThan: DateTime.now().subtract(Duration(days: 1)))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Meal.fromFirestore(doc)).toList());
  }

  Future<void> addMeal(Meal meal) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    await _firestore.collection('Users').doc(uid).collection('Meals').add(meal.toFirestore());
  }

  Future<void> deleteOldMeals() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    QuerySnapshot snapshot = await _firestore
        .collection('Users')
        .doc(uid)
        .collection('Meals')
        .where('timestamp', isLessThan: DateTime.now().subtract(Duration(days: 0)))
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
  Stream<Map<String, int>> getCaloriesStream() {
    return _firestore
        .collection('Users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('Meals')
        .where('timestamp', isGreaterThan: DateTime.now().subtract(Duration(days: 1)))
        .snapshots()
        .map((snapshot) {
      Map<String, int> caloriesByMealType = {'Завтрак': 0, 'Обед': 0, 'Ужин': 0};
      for (var doc in snapshot.docs) {
        Meal meal = Meal.fromFirestore(doc);
        caloriesByMealType[meal.type] = (caloriesByMealType[meal.type] ?? 0) + meal.calories;
      }
      return caloriesByMealType;
    });
  }
  Stream<double> getWaterStream() {
    return _firestore
        .collection('Users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final waterTimestamp = data['waterTimestamp']?.toDate() ?? DateTime.now();
        if (_isSameDay(waterTimestamp, DateTime.now())) {
          return data['totalWater']?.toDouble() ?? 0.0;
        }
      }
      return 0.0;
    });
  }

  Stream<List<double>> getWeightStream() {
    return _firestore
        .collection('Users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return List<double>.from(snapshot.data()!['weightData'] ?? []);
      }
      return [];
    });
  }
  Stream<String> getStepsStream() {
    // Реализуйте метод для получения данных о шагах
    // Например, если данные о шагах также хранятся в Firestore:
    return _firestore
        .collection('Users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.data()!['steps'].toString();
      }
      return '0';
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
}

