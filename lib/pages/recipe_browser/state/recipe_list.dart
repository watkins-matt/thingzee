import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mealie_api/mealie_api.dart';
import 'package:thingzee/pages/recipe_browser/state/recipe.dart';

final recipeListProvider = StateNotifierProvider<RecipeList, List<Recipe>>((ref) => RecipeList());

class RecipeList extends StateNotifier<List<Recipe>> {
  RecipeList() : super([]);

  void addRecipe(Recipe recipe) {
    state = [...state, recipe];
  }

  Future<void> fetchRecipes(MealieApiClient client) async {
    var mealieRecipes = await fetchAllRecipes(client);
    state = mealieRecipes.map((mealieRecipe) => Recipe.fromMealieRecipe(mealieRecipe)).toList();
  }

  void removeRecipe(String id) {
    state = state.where((recipe) => recipe.id != id).toList();
  }
}
