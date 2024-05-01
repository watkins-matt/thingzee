import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SelectionWidget extends ConsumerWidget {
  const SelectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: TextFormField(
        onFieldSubmitted: (value) {},
        decoration: const InputDecoration(
          labelText: 'Update Quantity',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
