import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/inventory/state/inventory_display.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/inventory/view_dialog.dart';

class ViewButton extends ConsumerWidget {
  const ViewButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.view_list),
      onPressed: () async {
        final display = ref.read(inventoryDisplayProvider);
        final branded = ref.read(inventoryProvider.notifier).filter.displayBranded;

        await ViewDialog.show(context, display.displayImages, branded);
      },
    );
  }
}
