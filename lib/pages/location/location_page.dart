import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/location/state/location_view_state.dart';
import 'package:thingzee/pages/location/widgets/location_view_grid.dart';
import 'package:thingzee/pages/location/widgets/location_view_list.dart';
import 'package:thingzee/pages/location/widgets/path_chip_widget.dart';

class LocationPage extends ConsumerStatefulWidget {
  const LocationPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends ConsumerState<LocationPage> {
  bool useGridView = false;

  @override
  @override
  Widget build(BuildContext context) {
    final currentDirectory =
        ref.watch(locationViewProvider.select((value) => value.currentDirectory));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            ref.read(locationViewProvider.notifier).changeDirectory('/');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              ref.read(locationViewProvider.notifier).back();
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {
              ref.read(locationViewProvider.notifier).forward();
            },
          ),
        ],
        title: PathChipWidget(
          fullPath: currentDirectory,
          onTap: (path) {
            ref.read(locationViewProvider.notifier).changeDirectory(path);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: useGridView ? const LocationGridView() : const LocationListView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => useGridView = !useGridView),
        child: Icon(useGridView ? Icons.list : Icons.grid_view),
      ),
    );
  }
}
