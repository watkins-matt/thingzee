import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:thingzee/pages/detail/item_detail_page.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';

class ItemGridTile extends ConsumerWidget {
  final Item item;
  final Inventory inventory;
  final bool brandedName;

  const ItemGridTile(this.item, this.inventory, {super.key, this.brandedName = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailCache = ref.watch(itemThumbnailCache);
    ImageProvider? imageProvider;

    if (item.imageUrl.isNotEmpty &&
        thumbnailCache.containsKey(item.upc) &&
        thumbnailCache[item.upc] != null) {
      imageProvider = thumbnailCache[item.upc]!.image;
    } else {
      imageProvider = const AssetImage('assets/images/no_image_available.png');
    }

    // Use the preferred amount string, and for consumable items
    // include an asterisk if we are not able to predict the amount
    String amountString =
        inventory.preferredAmountString + (!item.consumable || inventory.canPredict ? '' : '*');

    // Do not show decimal places for non-consumable items
    if (!item.consumable) {
      amountString = inventory.amount.toStringAsFixed(0);
    }

    return Material(
      child: InkWell(
        onTap: () async {
          await ItemDetailPage.push(context, ref, item, inventory);
        },
        child: Card(
          elevation: 2,
          child: GridTile(
            footer: GridTileBar(
              title: Text(
                brandedName || item.type.isEmpty ? item.name : item.type,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: 2,
              ),
              trailing: Text(
                amountString,
                textAlign: TextAlign.left,
                style: TextStyle(
                    color: inventory.predictedAmount > 0.5 ? Colors.green : Colors.red,
                    fontSize: 24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 48, left: 0, right: 0),
              child: Ink.image(image: imageProvider, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
