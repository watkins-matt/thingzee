import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/shopping_list_database.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:thingzee/pages/detail/item_detail_page.dart';
import 'package:thingzee/pages/shopping/price_entry_dialog.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';

class ShoppingListTile extends HookConsumerWidget {
  final ShoppingItem item;
  final bool editable;
  final bool checkbox;

  ShoppingListTile({
    required this.item,
    this.editable = true,
    this.checkbox = true,
  }) : super(key: ValueKey(item.uid));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(shoppingListProvider);
    final isCart = item.listName == ShoppingListName.cart;
    final TextEditingController controller = useTextEditingController(text: item.name);
    final FocusNode focusNode = useFocusNode();

    return InkWell(
      onLongPress: () => onLongPress(context, ref, item),
      child: Dismissible(
        key: ValueKey(item.uid),
        background: buildDismissibleBackground(),
        dismissThresholds: buildDismissThresholds(),
        onDismissed: (_) => onDismissed(ref),
        child: ListTile(
          leading: checkbox
              ? Checkbox(
                  value: item.checked,
                  onChanged: (bool? value) => checkedStatusChanged(ref, value ?? !item.checked),
                  visualDensity: VisualDensity.compact,
                )
              : null,
          title: editable ? buildEditableTitle(ref, controller, focusNode) : buildTitle(),
          trailing: isCart ? buildPriceButton(context) : null,
        ),
      ),
    );
  }

  Widget buildDismissibleBackground() => Container(color: Colors.red);

  Map<DismissDirection, double> buildDismissThresholds() => const {
        DismissDirection.endToStart: 0.9,
        DismissDirection.startToEnd: 0.9,
      };

  Widget buildEditableTitle(WidgetRef ref, TextEditingController controller, FocusNode focusNode) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      style: TextStyle(
        decoration: checkbox && item.checked ? TextDecoration.lineThrough : TextDecoration.none,
      ),
      decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Enter item name',
          isDense: true,
          contentPadding: EdgeInsets.all(0)),
      onFieldSubmitted: (value) {
        final updatedItem = item.copyWith(name: value);
        ref.read(shoppingListProvider.notifier).updateItem(updatedItem);
        focusNode.unfocus();
      },
      maxLines: null,
    );
  }

  Widget buildPriceButton(BuildContext context) => ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
        ),
        onPressed: () async => await PriceEntryDialog.show(context),
        child: const Text('Price'),
      );

  Widget buildTitle() => Text(
        item.name,
        style: TextStyle(
          decoration: checkbox && item.checked ? TextDecoration.lineThrough : TextDecoration.none,
        ),
        maxLines: null,
      );

  void checkedStatusChanged(WidgetRef ref, bool checked) {
    ref.read(shoppingListProvider.notifier).check(item, checked);
  }

  void onDismissed(WidgetRef ref) {
    ref.read(shoppingListProvider.notifier).remove(item);
  }

  Future<void> onLongPress(BuildContext context, WidgetRef ref, ShoppingItem shoppingItem) async {
    await ItemDetailPage.push(context, ref, shoppingItem.item, shoppingItem.inventory);
  }
}
