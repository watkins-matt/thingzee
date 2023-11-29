import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:repository/database/joined_item_database.dart';
import 'package:thingzee/pages/detail/item_detail_page.dart';
import 'package:thingzee/pages/shopping/state/shopping_cart.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';

class ShoppingListTile extends StatelessWidget {
  final int index;
  final JoinedItem joinedItem;
  final ShoppingListState sl;
  final ShoppingCartState sc;
  final WidgetRef ref;

  const ShoppingListTile({
    super.key,
    required this.index,
    required this.joinedItem,
    required this.sl,
    required this.sc,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final item = joinedItem.item;
    final inventory = joinedItem.inventory;

    return InkWell(
      onLongPress: () async {
        await ItemDetailPage.push(context, ref, item, inventory);
      },
      child: Dismissible(
        key: UniqueKey(),
        background: Container(color: Colors.red),
        dismissThresholds: const {
          DismissDirection.endToStart: 0.9,
          DismissDirection.startToEnd: 0.9,
        },
        onDismissed: (_) {
          ref.read(shoppingListProvider.notifier).removeAt(index);
          ref.read(shoppingCartProvider.notifier).remove(joinedItem);
        },
        child: CheckboxListTile(
          value: sl.checked.contains(item.upc),
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (value) {
            ref.read(shoppingListProvider.notifier).check(index, value ?? false);

            if (sl.checked.contains(item.upc)) {
              ref.read(shoppingCartProvider.notifier).add(joinedItem);
            } else {
              ref.read(shoppingCartProvider.notifier).remove(joinedItem);
            }
          },
          title: Text(
            item.name,
            style: TextStyle(
              decoration:
                  sl.checked.contains(item.upc) ? TextDecoration.lineThrough : TextDecoration.none,
            ),
          ),
          subtitle: inventory.canPredict
              ? Text('Out on ${DateFormat.yMMMd().format(inventory.predictedOutDate)}',
                  style: TextStyle(
                      decoration: sl.checked.contains(item.upc)
                          ? TextDecoration.lineThrough
                          : TextDecoration.none))
              : null,
          secondary: Text(
            inventory.preferredAmountString,
            style: TextStyle(
                color: inventory.predictedAmount > 0.5 ? Colors.green : Colors.red, fontSize: 24),
          ),
        ),
      ),
    );
  }
}
