import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';
import 'package:thingzee/pages/shopping/widget/animated_list_view.dart';
import 'package:thingzee/pages/shopping/widget/shopping_list_tile.dart';

class AnimatedShoppingListView extends ConsumerWidget {
  final bool Function(ShoppingItem) filter;
  final bool editable;

  const AnimatedShoppingListView({
    super.key,
    required this.filter,
    this.editable = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredItems = ref.watch(
      shoppingListProvider.select((value) => value.shoppingItems.where(filter).toList()),
    );

    return AnimatedListView<ShoppingItem>(
      items: filteredItems,
      itemBuilder: (context, item) => ShoppingListTile(
        key: UniqueKey(),
        item: item,
        editable: editable,
        checkbox: true,
        autoFocus: editable && item == filteredItems.last && item.name.isEmpty,
        onChecked: (uid, checked) {
          ref.read(shoppingListProvider.notifier).check(item, checked);
        },
      ),
      onDismiss: (item) {
        ref.read(shoppingListProvider.notifier).remove(item);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} removed'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                ref.read(shoppingListProvider.notifier).undoRemove(item);
              },
            ),
          ),
        );
      },
    );
  }
}
