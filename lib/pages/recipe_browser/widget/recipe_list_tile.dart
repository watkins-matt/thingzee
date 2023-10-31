import 'package:flutter/material.dart';
import 'package:thingzee/pages/recipe_browser/state/recipe.dart';

class RecipeListTile extends StatelessWidget {
  final Recipe recipe;

  const RecipeListTile({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    bool isValidUrl = false;
    try {
      Uri.parse(recipe.imageUrl);
      isValidUrl = true;
    } catch (e) {
      isValidUrl = false;
    }

    final imageWidget = isValidUrl
        ? Image.network(
            recipe.imageUrl,
            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
              return Container(); // The recipe does not have an associated image
            },
            fit: BoxFit.cover,
          )
        : null;

    final leadingWidget = imageWidget != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageWidget,
          )
        : imageWidget;

    return ListTile(
      leading: leadingWidget == null
          ? null
          : SizedBox(
              height: 100,
              width: 100,
              child: leadingWidget,
            ),
      title: Text(recipe.name),
      onTap: () {},
    );
  }
}
