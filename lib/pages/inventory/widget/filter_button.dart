import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/inventory/filter_dialog.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';

class FilterButton extends ConsumerWidget {
  const FilterButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
        icon: const Icon(Icons.filter_list),
        onPressed: () async {
          final view = ref.read(inventoryProvider.notifier);

          final filterResult = await FilterDialog.show(context, view.filter);
          view.filter = filterResult;

          await view.refresh();
        });
  }
}