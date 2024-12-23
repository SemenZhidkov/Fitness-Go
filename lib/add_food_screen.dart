import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'meal.dart';

class AddFoodScreen extends StatefulWidget {
  final String mealType;

  AddFoodScreen({required this.mealType});

  @override
  _AddFoodScreenState createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _proteinsController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _servingSizeController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();

  Future<void> _addFoodItem() async {
    String name = _nameController.text;
    double proteins = double.tryParse(_proteinsController.text) ?? 0;
    double fats = double.tryParse(_fatsController.text) ?? 0;
    double carbs = double.tryParse(_carbsController.text) ?? 0;
    int servingSize = int.tryParse(_servingSizeController.text) ?? 0;
    int calories = int.tryParse(_caloriesController.text) ?? 0;

    FoodItem foodItem = FoodItem(
      name: name,
      proteins: proteins,
      fats: fats,
      carbs: carbs,
      servingSize: servingSize,
      calories: calories,
    );

    String uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('Users').doc(uid).collection('Meals').add(foodItem.toFirestore());

    Navigator.pop(context, foodItem);
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить продукт'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Название'),
            ),
            TextField(
              controller: _proteinsController,
              decoration: InputDecoration(labelText: 'Белки (г)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _fatsController,
              decoration: InputDecoration(labelText: 'Жиры (г)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _carbsController,
              decoration: InputDecoration(labelText: 'Углеводы (г)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _servingSizeController,
              decoration: InputDecoration(labelText: 'Размер порции (г)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _caloriesController,
              decoration: InputDecoration(labelText: 'Калории (ккал)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addFoodItem,
              child: Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }
}
