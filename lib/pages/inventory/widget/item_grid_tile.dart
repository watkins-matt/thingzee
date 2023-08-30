import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:thingzee/pages/detail/item_detail_page.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';

class ItemGridTile extends ConsumerWidget {
  final Item item;
  final Inventory inventory;

  const ItemGridTile(this.item, this.inventory, {Key? key}) : super(key: key);

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

    return InkWell(
      onTap: () async {
        await ItemDetailPage.push(context, ref, item, inventory);
      },
      child: Card(
        elevation: 2,
        child: GridTile(
          footer: GridTileBar(
            title: Text(
              item.name,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              textScaleFactor: 1,
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 2,
            ),
            trailing: Text(
              inventory.preferredAmountString + (inventory.canPredict ? '' : '*'),
              textAlign: TextAlign.left,
              textScaleFactor: 1.5,
              style: TextStyle(
                color: inventory.predictedAmount > 0.5 ? Colors.green : Colors.red,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 48, left: 0, right: 0),
            child: Ink.image(image: imageProvider, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
