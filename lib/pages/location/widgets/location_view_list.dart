import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/detail/widget/material_card_widget.dart';
import 'package:thingzee/pages/inventory/widget/item_list_tile.dart';
import 'package:thingzee/pages/location/state/location_view_state.dart';

class LocationListView extends ConsumerWidget {
  const LocationListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subPaths = ref.watch(locationViewProvider).subPaths;
    final currentItems = ref.watch(locationViewProvider).currentItems;

    return ListView.builder(
      itemCount: subPaths.length + currentItems.length,
      itemBuilder: (context, index) {
        // Handle subpaths
        if (index < subPaths.length) {
          final subPath = subPaths[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: MaterialCardWidget(padding: 0, children: [
              ListTile(
                onTap: () => ref.read(locationViewProvider.notifier).changeDirectory(subPath),
                title: Row(
                  children: [
                    const Icon(Icons.folder, size: 50, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        subPath,
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          );
        }

        // Handle items
        else {
          final itemIndex = index - subPaths.length;
          final joinedItem = currentItems[itemIndex];
          return ItemListTile(joinedItem.item, joinedItem.inventory);
        }
      },
    );
  }
}
