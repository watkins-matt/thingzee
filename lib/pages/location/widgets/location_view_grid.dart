import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/inventory/widget/item_grid_tile.dart';
import 'package:thingzee/pages/location/state/location_view_state.dart';

class LocationGridView extends ConsumerWidget {
  const LocationGridView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subPaths = ref.watch(locationViewProvider).subPaths;
    final currentItems = ref.watch(locationViewProvider).currentItems;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: subPaths.length + currentItems.length,
      itemBuilder: (context, index) {
        // Handle subpaths
        if (index < subPaths.length) {
          final subPath = subPaths[index];
          return GestureDetector(
            onTap: () => ref.read(locationViewProvider.notifier).changeDirectory(subPath),
            child: Card(
              elevation: 4,
              child: GridTile(
                footer: GridTileBar(
                  title: Text(
                    subPath,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.folder,
                    size: 50,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          );
        }

        // Handle items
        else {
          final itemIndex = index - subPaths.length;
          final joinedItem = currentItems[itemIndex];
          return ItemGridTile(joinedItem.item, joinedItem.inventory);
        }
      },
    );
  }
}
