import 'package:flutter/material.dart';

class LocationChipView extends StatelessWidget {
  final Set<String> locations;
  final Function(String) onLocationRemove;

  const LocationChipView({super.key, required this.locations, required this.onLocationRemove});

  @override
  Widget build(BuildContext context) {
    List<String> sortedLocations = List.from(locations)..sort();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: sortedLocations.map((location) {
        return InputChip(
          label: Text(location),
          onPressed: () => onLocationRemove(location),
          deleteIcon: const Icon(Icons.close),
          onDeleted: () => onLocationRemove(location),
        );
      }).toList(),
    );
  }
}
