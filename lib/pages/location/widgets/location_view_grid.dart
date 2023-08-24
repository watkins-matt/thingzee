import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';
import 'package:thingzee/pages/location/state/location_view_state.dart';

class LocationGridView extends ConsumerWidget {
  const LocationGridView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(locationViewProvider).contents;
    final thumbnailCache = ref.watch(itemThumbnailCache);

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final location = locations[index];
        Image image;
        if (thumbnailCache.containsKey(location.upc) && thumbnailCache[location.upc] != null) {
          image = thumbnailCache[location.upc]!;
        } else {
          image = const Image(
            image: AssetImage('assets/images/no_image_available.png'),
            width: 100,
            height: 100,
          );
        }
        return GestureDetector(
          onTap: () => ref.read(locationViewProvider.notifier).changeDirectory(location.name),
          child: Card(
            elevation: 4,
            child: GridTile(
              footer: Center(child: Text(location.name)),
              child: image,
            ),
          ),
        );
      },
    );
  }
}
