import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/inventory/state/inventory_display.dart';

class ViewDialog extends ConsumerStatefulWidget {
  final bool defaultDisplayImages;

  const ViewDialog({
    Key? key,
    this.defaultDisplayImages = true,
  }) : super(key: key);

  const ViewDialog.fromDisplayImages(this.defaultDisplayImages, {Key? key}) : super(key: key);

  @override
  ConsumerState<ViewDialog> createState() => _ViewDialogState();

  static Future<bool> show(BuildContext context, bool displayImages) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => ViewDialog.fromDisplayImages(displayImages),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
    );
    return result ?? displayImages;
  }
}

class _ViewDialogState extends ConsumerState<ViewDialog> {
  bool displayImages = true;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'View',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Display',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Wrap(
            spacing: 8,
            children: <Widget>[
              ChoiceChip(
                label: const Text('Display Images'),
                selected: displayImages,
                onSelected: _toggleDisplayImages,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    displayImages = widget.defaultDisplayImages;
  }

  Future<void> _toggleDisplayImages(bool selected) async {
    setState(() {
      displayImages = selected;
    });
    await _updateView();
  }

  Future<void> _updateView() async {
    final view = ref.read(inventoryDisplayProvider.notifier);
    view.displayImages = displayImages;
  }
}
