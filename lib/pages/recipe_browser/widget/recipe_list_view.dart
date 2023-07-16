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
        return Card(
          margin: const EdgeInsets.all(8),
          surfaceTintColor: Colors.white,
          elevation: 3,
          child: ListTile(
            leading: Image.network(
              recipe.imageUrl,
              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                return Container();
              },
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
            title: Text(recipe.name),
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => RecipeDetail(recipe: recipe),
              //   ),
              // );
            },
          ),
        );
      },
    );
  }
}
