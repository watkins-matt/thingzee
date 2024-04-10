import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/item.dart';
import 'package:thingzee/pages/detail/widget/material_card_widget.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';

class PotentialItemMatchTile extends ConsumerWidget {
  final Item item;
  final bool showImage;
  final VoidCallback onTap;

  const PotentialItemMatchTile({
    super.key,
    required this.item,
    this.showImage = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cache = ref.watch(itemThumbnailCache);
    ImageProvider? imageProvider;

    if (showImage &&
        item.imageUrl.isNotEmpty &&
        cache.containsKey(item.upc) &&
        cache[item.upc] != null) {
      imageProvider = cache[item.upc]!.image;
    }

    return MaterialCardWidget(
      children: [
        ListTile(
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              Expanded(
                child: Text(item.name, style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
          subtitle: item.unitCount != 1 ? Text('Unit Count: ${item.unitCount}') : null,
          onTap: onTap,
        ),
      ],
    );
  }
}
