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
  final bool autoFocus;
  final void Function(String uid, bool checked)? onChecked;

  const ShoppingListTile({
    super.key,
    required this.item,
    this.editable = true,
    this.checkbox = true,
    this.autoFocus = false,
    this.onChecked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(shoppingListProvider);
    final isCart = item.listName == ShoppingListName.cart;
    final TextEditingController controller = useTextEditingController(text: item.name);
    final FocusNode focusNode = useFocusNode();
    final isEditing = useState(false);

    if (autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
      });
    }

    return InkWell(
      onLongPress: () => onLongPress(context, ref, item),
      onTap: () {
        if (editable && !isEditing.value) {
          isEditing.value = true;
          focusNode.requestFocus();
        }
      },
      child: ListTile(
        leading: checkbox
            ? Checkbox(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(
                  color: Colors.grey,
                  width: 2,
                ),
                value: item.checked,
                onChanged: (bool? value) => checkedStatusChanged(ref, value ?? !item.checked),
                visualDensity: VisualDensity.compact,
              )
            : null,
        title: editable && isEditing.value
            ? buildEditableTitle(ref, controller, focusNode, isEditing)
            : buildTitle(),
        trailing: isCart ? buildPriceButton(context, ref) : null,
      ),
    );
  }

  Widget buildEditableTitle(WidgetRef ref, TextEditingController controller, FocusNode focusNode,
      ValueNotifier<bool> isEditing) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.words,
      style: TextStyle(
        decoration: checkbox && item.checked ? TextDecoration.lineThrough : TextDecoration.none,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        hintText: 'Enter item name',
        isDense: true,
        contentPadding: EdgeInsets.all(0),
      ),
      onFieldSubmitted: (value) {
        final updatedItem = item.copyWith(name: value);
        ref.read(shoppingListProvider.notifier).updateItem(updatedItem);
        focusNode.unfocus();
        ref.read(shoppingListProvider.notifier).sortItems();
        isEditing.value = false;
      },
      maxLines: null,
    );
  }

  Widget buildPriceButton(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).textTheme.bodyLarge!.color!;
    final priceColor = item.price != 0 ? color : Colors.red;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return PriceEntryDialog(
              initialPrice: item.price,
              initialQuantity: item.quantity,
              onItemEdited: (double price, int quantity) {
                final updatedItem = item.copyWith(price: price, quantity: quantity);
                ref.read(shoppingListProvider.notifier).updateItem(updatedItem);
              },
            );
          },
        );
      },
      child: SizedBox(
        height: double.infinity,
        width: 60, // Width needs to be at least 60 to avoid line break
        child: Center(
          child: Text(
            '${item.quantity} x \$${item.price.toStringAsFixed(2)}',
            style: TextStyle(color: priceColor),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget buildTitle() => Text(
        item.name,
        style: TextStyle(
          decoration: checkbox && item.checked ? TextDecoration.lineThrough : TextDecoration.none,
        ),
        maxLines: null,
      );

  void checkedStatusChanged(WidgetRef ref, bool checked) {
    if (onChecked != null) {
      onChecked!(item.uid, checked);
    }
  }

  Future<void> onLongPress(BuildContext context, WidgetRef ref, ShoppingItem shoppingItem) async {
    await ItemDetailPage.push(context, ref, shoppingItem.item, shoppingItem.inventory);
  }
}
