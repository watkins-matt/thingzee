import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/recipe_browser/widget/recipe_list_view.dart';

class RecipeBrowser extends ConsumerWidget {
  const RecipeBrowser({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Recipe Browser'),
      ),
      body: const RecipeListView(),
    );
  }
}
