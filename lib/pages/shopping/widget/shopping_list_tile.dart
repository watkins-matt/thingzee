import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/shopping_list.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:thingzee/pages/detail/item_detail_page.dart';
import 'package:thingzee/pages/shopping/price_entry_dialog.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart'; // Ensure correct imports for context usage

class ShoppingListTile extends ConsumerWidget {
  final ShoppingItem item;

  const ShoppingListTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCart = item.listName == ShoppingListName.cart;

    return InkWell(
      onLongPress: () => _onLongPress(context, ref),
      child: Dismissible(
        key: ValueKey(item.uid),
        background: buildDismissibleBackground(),
        dismissThresholds: buildDismissThresholds(),
        onDismissed: (_) => _onDismissed(ref),
        child: isCart ? buildCartTile(context) : buildShoppingListTile(ref),
      ),
    );
  }

  Widget buildCartTile(BuildContext context) => ListTile(
        title: Text(item.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            buildPriceButton(context),
          ],
        ),
      );

  Widget buildDismissibleBackground() => Container(color: Colors.red);

  Map<DismissDirection, double> buildDismissThresholds() => const {
        DismissDirection.endToStart: 0.9,
        DismissDirection.startToEnd: 0.9,
      };

  Widget buildPriceButton(BuildContext context) => ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
        ),
        onPressed: () async => await PriceEntryDialog.show(context),
        child: const Text('Price'),
      );

  Widget buildShoppingListTile(WidgetRef ref) => CheckboxListTile(
        value: item.checked,
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: (value) => _onChanged(ref),
        title: buildTitle(),
      );

  Widget buildTitle() => Text(
        item.name,
        style: TextStyle(
          decoration: item.checked ? TextDecoration.lineThrough : TextDecoration.none,
        ),
      );

  void _onChanged(WidgetRef ref) {
    ref.read(shoppingListProvider.notifier).check(item.uid);
  }

  void _onDismissed(WidgetRef ref) {
    ref.read(shoppingListProvider.notifier).remove(item.uid);
  }

  Future<void> _onLongPress(BuildContext context, WidgetRef ref) async {
    await ItemDetailPage.push(context, ref, item.item, item.inventory);
  }
}
