import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/detail/state/editable_item.dart';
import 'package:thingzee/pages/history/widget/history_list_view.dart';

class HistoryPage extends ConsumerStatefulWidget {
  final String upc;
  const HistoryPage(this.upc, {Key? key}) : super(key: key);

  static Future<void> push(BuildContext context, String upc) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryPage(upc)),
    );
  }

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  List<MapEntry<int, double>> entries = [];

  @override
  void initState() {
    super.initState();

    final editableItem = ref.read(editableItemProvider.notifier);
    entries = editableItem.allHistoryEntries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: HistoryListView(entries: entries),
    );
  }
}
