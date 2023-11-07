import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/filter.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';

class FilterDialog extends ConsumerStatefulWidget {
  final Filter defaultFilter;

  const FilterDialog({super.key})
      : defaultFilter = const Filter();
  const FilterDialog.fromFilter(this.defaultFilter, {super.key});

  @override
  ConsumerState<FilterDialog> createState() => _FilterDialogState();

  static Future<Filter> show(BuildContext context, Filter filter) async {
    final result = await showModalBottomSheet<Filter>(
      context: context,
      builder: (context) => FilterDialog.fromFilter(filter),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
    );
    return result ?? const Filter();
  }
}

class _FilterDialogState extends ConsumerState<FilterDialog> {
  bool consumable = false;
  bool nonConsumable = false;
  bool outsOnly = false;

  Filter get filter => Filter(
        consumable: consumable,
        nonConsumable: nonConsumable,
        outsOnly: outsOnly,
      );

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
            'Filter',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Item Type',
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
                label: const Text('Consumable'),
                selected: consumable,
                onSelected: _toggleConsumable,
              ),
              ChoiceChip(
                label: const Text('Non-Consumable'),
                selected: nonConsumable,
                onSelected: _toggleNonConsumable,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Item Quantity',
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
                label: const Text('Outs Only'),
                selected: outsOnly,
                onSelected: _toggleOutsOnly,
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

    consumable = widget.defaultFilter.consumable;
    nonConsumable = widget.defaultFilter.nonConsumable;
    outsOnly = widget.defaultFilter.outsOnly;
  }

  Future<void> _toggleConsumable(bool selected) async {
    setState(() {
      consumable = selected;
      // If deselection is attempted while the other chip is also deselected,
      // set nonConsumable to true to ensure at least one chip remains selected.
      nonConsumable = (!selected && !nonConsumable) || nonConsumable;
    });
    await _updateView();
  }

  Future<void> _toggleNonConsumable(bool selected) async {
    setState(() {
      nonConsumable = selected;
      // If deselection is attempted while the other chip is also deselected,
      // set consumable to true to ensure at least one chip remains selected.
      consumable = (!selected && !consumable) || consumable;
    });
    await _updateView();
  }

  Future<void> _toggleOutsOnly(bool selected) async {
    setState(() {
      outsOnly = selected;
    });

    await _updateView();
  }

  Future<void> _updateView() async {
    final view = ref.read(inventoryProvider.notifier);
    view.filter = filter;
  }
}
