import 'package:flutter/material.dart';
import 'package:repository/model/filter.dart';

class FilterDialog extends StatefulWidget {
  final Filter defaultFilter;

  FilterDialog({Key? key})
      : defaultFilter = Filter(),
        super(key: key);
  const FilterDialog.fromFilter(this.defaultFilter, {Key? key}) : super(key: key);

  static Future<Filter> show(BuildContext context, Filter filter) async {
    final result = await showDialog<Filter>(
        context: context, builder: (context) => FilterDialog.fromFilter(filter));
    return result ?? Filter();
  }

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  bool consumable = false;
  bool nonConsumable = false;
  bool outs = false;

  @override
  void initState() {
    super.initState();

    consumable = widget.defaultFilter.consumable;
    nonConsumable = widget.defaultFilter.nonConsumable;
    outs = widget.defaultFilter.outs;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: 4,
            children: <Widget>[
              FilterChip(
                label: const Text('Consumable'),
                selected: consumable,
                onSelected: (bool selected) {
                  setState(() {
                    consumable = selected;
                    if (!selected && !nonConsumable) {
                      nonConsumable = true;
                    }
                  });
                },
              ),
              FilterChip(
                label: const Text('Non-Consumable'),
                selected: nonConsumable,
                onSelected: (bool selected) {
                  setState(() {
                    nonConsumable = selected;
                    if (!selected && !consumable) {
                      consumable = true;
                    }
                  });
                },
              ),
              FilterChip(
                label: const Text('Outs'),
                selected: outs,
                onSelected: (bool selected) {
                  setState(() {
                    outs = selected;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Navigator.pop(
                context, Filter(consumable: consumable, nonConsumable: nonConsumable, outs: outs));
          },
          child: const Text('OK'),
        )
      ],
    );
  }
}
