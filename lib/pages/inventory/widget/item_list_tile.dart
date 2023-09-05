import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:thingzee/pages/detail/item_detail_page.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';

class ItemListTile extends ConsumerWidget {
  final Item item;
  final Inventory inventory;
  const ItemListTile(this.item, this.inventory, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cache = ref.watch(itemThumbnailCache);
    ImageProvider? imageProvider;

    if (item.imageUrl.isNotEmpty && cache.containsKey(item.upc) && cache[item.upc] != null) {
      imageProvider = cache[item.upc]!.image;
    }

    return Material(
      child: InkWell(
          onTap: () => onTap(context, ref),
          child: ListTile(
            title: Row(
              children: [
                if (imageProvider != null)
                  Row(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 100,
                          minHeight: 100,
                          maxWidth: 100,
                          maxHeight: 100,
                        ),
                        child: Ink.image(image: imageProvider, fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                Expanded(
                  child: Text(item.name, softWrap: true),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      inventory.preferredAmountString + (inventory.canPredict ? '' : '*'),
                      textAlign: TextAlign.right,
                      textScaleFactor: 1.5,
                      style: TextStyle(
                          color: inventory.predictedAmount > 0.5 ? Colors.green : Colors.red),
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
