import 'package:cloud_firestore/cloud_firestore.dart';

class Meal {
  final String name;
  final double proteins;
  final double fats;
  final double carbs;
  final int calories;
  final Timestamp timestamp;
  final String type;

  Meal({
    required this.name,
    required this.proteins,
    required this.fats,
    required this.carbs,
    required this.calories,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'proteins': proteins,
      'fats': fats,
      'carbs': carbs,
      'calories': calories,
      'timestamp': timestamp,
      'type': type,
    };
  }
  
  static Meal fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Meal(
      name: data['name'] ?? 'Unknown',
      proteins: (data['proteins'] ?? 0).toDouble(),
      fats: (data['fats'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      calories: data['calories'] ?? 0,
      timestamp: data['timestamp'] ?? Timestamp.now(),
      type: data['type'] ?? 'Unknown',
    );
  }
}
class FoodItem {
  final String name;
  final double proteins;
  final double fats;
  final double carbs;
  final int servingSize;
  final int calories;

  FoodItem({
    required this.name,
    required this.proteins,
    required this.fats,
    required this.carbs,
    required this.servingSize,
    required this.calories,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'proteins': proteins,
      'fats': fats,
      'carbs': carbs,
      'servingSize': servingSize,
      'calories': calories,
    };
  }

  static FoodItem fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      name: data['name'],
      proteins: data['proteins'],
      fats: data['fats'],
      carbs: data['carbs'],
      servingSize: data['servingSize'],
      calories: data['calories'],
    );
  }
  Meal toMeal(String type) {
    return Meal(
      name: name,
      proteins: proteins,
      fats: fats,
      carbs: carbs,
      calories: calories,
      timestamp: Timestamp.now(),
      type: type,
    );
  }

  static FoodItem fromMeal(Meal meal) {
    return FoodItem(
      name: meal.name,
      proteins: meal.proteins,
      fats: meal.fats,
      carbs: meal.carbs,
      servingSize: 0, // Если у вас нет этого параметра в Meal, установите значение по умолчанию
      calories: meal.calories,
    );
  }
}

