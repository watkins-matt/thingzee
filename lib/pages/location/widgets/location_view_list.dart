import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';
import 'package:thingzee/pages/location/state/location_view_state.dart';

class LocationListView extends ConsumerWidget {
  const LocationListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(locationViewProvider).contents;
    final thumbnailCache = ref.watch(itemThumbnailCache);

    return ListView.builder(
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
        return ListTile(
          onTap: () => ref.read(locationViewProvider.notifier).changeDirectory(location.name),
          leading: image,
          title: Text(location.name),
        );
      },
    );
  }
}
