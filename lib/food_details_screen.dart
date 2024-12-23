import 'package:fitnessgo/add_food_screen.dart';
import 'package:flutter/material.dart';
import 'service_stream.dart';
import 'meal.dart';

class FoodDetailsScreen extends StatefulWidget {
  final String mealType;

  FoodDetailsScreen({required this.mealType});

  @override
  _FoodDetailsScreenState createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  List<FoodItem> foodItems = [];
  final MealService mealService = MealService();

  @override
  void initState() {
    super.initState();
    _loadFoodItems();
  }

  void _loadFoodItems() {
    mealService.getMeals().listen((meals) {
      setState(() {
        foodItems = meals
            .where((meal) => meal.type == widget.mealType)
            .map((meal) => FoodItem.fromMeal(meal))
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mealType),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: foodItems.length,
              itemBuilder: (context, index) {
                return _buildFoodItemCard(foodItems[index]);
              },
            ),
          ),
          SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddFoodScreen(mealType: widget.mealType),
            ),
          );
          if (result != null && result is FoodItem) {
            setState(() {
              foodItems.add(result);
              mealService.addMeal(result.toMeal(widget.mealType)); // Используем метод toMeal
            });
          }
        },
        label: Text('Добавить продукт'),
        icon: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Card _buildFoodItemCard(FoodItem item) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ListTile(
        title: Text(item.name),
        subtitle: Text('Белки: ${item.proteins}г, Жиры: ${item.fats}г, Углеводы: ${item.carbs}г, Калории: ${item.calories}ккал'),
      ),
    );
  }
}
