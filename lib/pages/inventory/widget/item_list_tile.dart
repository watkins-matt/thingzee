import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:thingzee/pages/detail/item_detail_page.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';
import 'package:thingzee/pages/settings/state/settings_state.dart';

class ItemListTile extends ConsumerWidget {
  final Item item;
  final Inventory inventory;
  final bool brandedName;
  final bool image;

  const ItemListTile(this.item, this.inventory,
      {super.key, this.brandedName = true, this.image = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cache = ref.watch(itemThumbnailCache);
    ImageProvider? imageProvider;

    if (item.imageUrl.isNotEmpty && cache.containsKey(item.upc) && cache[item.upc] != null) {
      imageProvider = cache[item.upc]!.image;
    }

    // Use the preferred amount string, and for consumable items
    // include an asterisk if we are not able to predict the amount
    String amountString =
        item.consumable ? inventory.preferredAmountString : inventory.amount.toStringAsFixed(0);

    // If we can't predict the item, add an asterisk to the amount
    if (item.consumable && !inventory.canPredict) {
      amountString += '*';
    }

    final isDarkMode = ref.watch(isDarkModeProvider(context));

    Widget imageWidget = imageProvider != null && image
        ? isDarkMode
            ? Image(
                image: imageProvider,
                fit: BoxFit.contain,
              )
            : Ink.image(
                image: imageProvider,
                fit: BoxFit.contain,
              )
        : Container();

    Widget roundedWidget = isDarkMode
        ? ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageWidget,
          )
        : imageWidget;

    return Material(
      child: InkWell(
          onTap: () => onTap(context, ref),
          child: ListTile(
            title: Row(
              children: [
                if (image)
                  Row(
                    children: [
                      ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 100,
                            minHeight: 100,
                            maxWidth: 100,
                            maxHeight: 100,
                          ),
                          child: roundedWidget),
                      const SizedBox(width: 10),
                    ],
                  ),
                Expanded(
                  child: Text(brandedName || item.type.isEmpty ? item.name : item.type,
                      softWrap: true),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      amountString,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: inventory.predictedAmount > 0.5 ? Colors.green : Colors.red,
                          fontSize: 24),
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }

  Future<void> onTap(BuildContext context, WidgetRef ref) async {
    await ItemDetailPage.push(context, ref, item, inventory);
  }
}
