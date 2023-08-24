import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/location/widgets/location_view_grid.dart';
import 'package:thingzee/pages/location/widgets/location_view_list.dart';

class LocationPage extends ConsumerStatefulWidget {
  const LocationPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends ConsumerState<LocationPage> {
  bool useGridView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: useGridView ? const LocationGridView() : const LocationListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => useGridView = !useGridView),
        child: Icon(useGridView ? Icons.list : Icons.grid_view),
      ),
    );
  }
}
