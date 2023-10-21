import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/inventory/state/inventory_display.dart';
import 'package:thingzee/pages/inventory/view_dialog.dart';

class ViewButton extends ConsumerWidget {
  const ViewButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.view_list),
      onPressed: () async {
        final display = ref.read(inventoryDisplayProvider);
        await ViewDialog.show(context, display.displayImages);
      },
    );
  }
}
