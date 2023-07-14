import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mealie_api/bearer_interceptor.dart';
import 'package:mealie_api/mealie_api.dart';
import 'package:thingzee/pages/recipe_browser/state/recipe.dart';
import 'package:thingzee/pages/settings/state/preference_keys.dart';
import 'package:thingzee/pages/settings/state/settings_state.dart';

final recipeListProvider = StateNotifierProvider<RecipeList, List<Recipe>>((ref) {
  final mealieUrl = ref.watch(settingsProvider.select((s) => s.settings[PreferenceKey.mealieURL]));
  final mealieApiKey =
      ref.watch(settingsProvider.select((s) => s.secureSettings[SecurePreferenceKey.mealieApiKey]));

  if (mealieUrl != null && mealieApiKey != null) {
    final dio = Dio();
    dio.interceptors.add(BearerInterceptor(mealieApiKey));
    final client = MealieApiClient(dio, baseUrl: mealieUrl);
    return RecipeList(client);
  } else {
    return RecipeList();
  }
});

class RecipeList extends StateNotifier<List<Recipe>> {
  MealieApiClient? client;
  RecipeList([this.client]) : super([]) {
    refresh();
  }

  void addRecipe(Recipe recipe) {
    state = [...state, recipe];
  }

  Future<void> refresh() async {
    if (client == null) {
      return;
    }

    var mealieRecipes = await fetchAllRecipes(client!);
    state = mealieRecipes.map((mealieRecipe) => Recipe.fromMealieRecipe(mealieRecipe)).toList();
  }

  void removeRecipe(String id) {
    state = state.where((recipe) => recipe.id != id).toList();
  }
}
