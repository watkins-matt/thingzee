import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryListView extends StatelessWidget {
  const HistoryListView({
    Key? key,
    required this.entries,
    this.isScrollable = true,
  }) : super(key: key);

  final List<MapEntry<int, double>> entries;
  final bool isScrollable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: !isScrollable,
            physics: isScrollable ? null : const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: entries.length,
            itemBuilder: (BuildContext context, int index) {
              MapEntry<int, double> entry = entries[index];
              DateTime date = DateTime.fromMillisecondsSinceEpoch(entry.key);
              double amount = entry.value;

              return ListTile(
                title: Text(
                  DateFormat.yMMMd().add_jm().format(date),
                  softWrap: true,
                ),
                trailing: Text(amount.toStringAsFixed(2), textScaleFactor: 1.5),
              );
            },
            separatorBuilder: (context, index) => const Divider(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
