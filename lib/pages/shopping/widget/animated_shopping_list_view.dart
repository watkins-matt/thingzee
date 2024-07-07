import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';
import 'package:thingzee/pages/shopping/widget/animated_list_view.dart';
import 'package:thingzee/pages/shopping/widget/shopping_list_tile.dart';

class AnimatedShoppingListView extends ConsumerWidget {
  const AnimatedShoppingListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uncheckedItems = ref.watch(
      shoppingListProvider
          .select((value) => value.shoppingItems.where((item) => !item.checked).toList()),
    );

    return AnimatedListView<ShoppingItem>(
      items: uncheckedItems,
      itemBuilder: (context, item) => ShoppingListTile(
        item: item,
        checkbox: true,
        autoFocus: false,
        onChecked: (uid, checked) {
          if (checked) {
            ref.read(shoppingListProvider.notifier).check(item, true);
          }
        },
      ),
    );
  }
}
