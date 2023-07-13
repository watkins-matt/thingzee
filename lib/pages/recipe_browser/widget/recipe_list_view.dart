import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/recipe_browser/state/recipe_list.dart';

class RecipeListView extends ConsumerWidget {
  const RecipeListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(recipeListProvider);

    return ListView.builder(
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return ListTile(
          leading: Image.network(recipe.imageUrl),
          title: Text(recipe.name),
          onTap: () {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //         builder: (context) => RecipeDetail(recipe: recipe),
            //         ),
            //   );
          },
        );
      },
    );
  }
}
