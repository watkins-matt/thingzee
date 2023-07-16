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
        bool isValidUrl = false;
        try {
          Uri.parse(recipe.imageUrl);
          isValidUrl = true;
        } catch (e) {
          isValidUrl = false;
        }
        return Card(
          surfaceTintColor: Colors.white,
          elevation: 3,
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: isValidUrl
                ? SizedBox(
                    height: 50,
                    width: 50,
                    child: Image.network(
                      recipe.imageUrl,
                      errorBuilder:
                          (BuildContext context, Object exception, StackTrace? stackTrace) {
                        // The recipe does not have an associated image
                        return Container();
                      },
                      fit: BoxFit.cover,
                    ),
                  )
                : null,
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
