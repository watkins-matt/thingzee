import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/recipe_browser/state/recipe.dart';
import 'package:thingzee/pages/recipe_browser/state/recipe_list.dart';
import 'package:thingzee/pages/recipe_browser/widget/recipe_list_tile.dart';

class RecipeListView extends ConsumerWidget {
  const RecipeListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(recipeListProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        return _buildListItem(context, ref, recipes[index], isDarkMode);
      },
    );
  }

  Widget _buildListItem(BuildContext context, WidgetRef ref, Recipe recipe, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        shape: const RoundedRectangleBorder(),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RecipeListTile(recipe: recipe),
            ],
          ),
        ),
      ),
    );
  }
}
