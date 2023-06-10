import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:thingzee/app.dart';
import 'package:thingzee/pages/detail/item_detail_page.dart';
import 'package:thingzee/pages/detail/state/editable_item.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';

class ItemListTile extends ConsumerWidget {
  final Item item;
  final Inventory inventory;
  const ItemListTile(this.item, this.inventory, {Key? key}) : super(key: key);

  Future<void> onTap(BuildContext context, WidgetRef ref) async {
    final history = App.repo.hist.get(item.upc);
    final itemProv = ref.watch(editableItemProvider.notifier);
    itemProv.copyFrom(item, inventory, history);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ItemDetailPage(item)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cache = ref.watch(itemThumbnailCache);
    ImageProvider? imageProvider;

    if (item.imageUrl.isNotEmpty && cache.containsKey(item.upc) && cache[item.upc] != null) {
      imageProvider = cache[item.upc]!.image;
    }

    return InkWell(
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
                    inventory.preferredPredictedUnitString,
                    textAlign: TextAlign.right,
                    textScaleFactor: 1.5,
                    style: TextStyle(
                        color:
                            inventory.preferredPredictedAmount > 0.5 ? Colors.green : Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
