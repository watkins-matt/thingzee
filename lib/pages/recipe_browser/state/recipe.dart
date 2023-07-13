import 'package:mealie_api/mealie_api.dart';

class Recipe {
  final String id;
  final String name;
  final String imageUrl;

  Recipe({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory Recipe.fromMealieRecipe(MealieRecipe mealieRecipe) {
    return Recipe(
      id: mealieRecipe.id ?? '',
      name: mealieRecipe.name ?? '',
      imageUrl: mealieRecipe.image ?? '',
    );
  }

  MealieRecipe toMealieRecipe() {
    return MealieRecipe(
      id: id,
      name: name,
      image: imageUrl,
    );
  }
}
