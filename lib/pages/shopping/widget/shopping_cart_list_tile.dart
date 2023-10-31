import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/joined_item_database.dart';
import 'package:thingzee/pages/detail/item_detail_page.dart';
import 'package:thingzee/pages/shopping/price_entry_dialog.dart';
import 'package:thingzee/pages/shopping/state/shopping_cart.dart';

class ShoppingCartListTile extends ConsumerWidget {
  final JoinedItem joinedItem;
  final int index;

  const ShoppingCartListTile({Key? key, required this.joinedItem, required this.index})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          ref.read(shoppingCartProvider.notifier).removeAt(index);
        },
        child: ListTile(
            title: Text(item.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
                    foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                  ),
                  onPressed: () async => await PriceEntryDialog.show(context),
                  child: const Text('Price'),
                ),
              ],
            )),
      ),
    );
  }
}
