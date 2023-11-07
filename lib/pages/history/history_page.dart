import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/detail/state/editable_item.dart';
import 'package:thingzee/pages/history/widget/history_series_list_view.dart';

class HistoryPage extends ConsumerStatefulWidget {
  final String upc;
  const HistoryPage(this.upc, {super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();

  static Future<void> push(BuildContext context, String upc) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryPage(upc)),
    );
  }
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  List<MapEntry<int, double>> entries = [];

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(editableItemProvider).inventory.history;

    return Scaffold(
      appBar: AppBar(),
      body: HistorySeriesListView(history: history, onDeleteSeries: onDeleteSeries),
    );
  }

  @override
  void initState() {
    super.initState();

    final editableItem = ref.read(editableItemProvider.notifier);
    entries = editableItem.allHistoryEntries;
  }

  void onDeleteSeries(int index) {
    final editableItem = ref.read(editableItemProvider.notifier);
    editableItem.deleteHistorySeries(index);
  }
}
