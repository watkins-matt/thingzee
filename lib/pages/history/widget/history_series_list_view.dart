import 'package:flutter/material.dart';
import 'package:repository/ml/history.dart';
import 'package:thingzee/pages/detail/widget/material_card_widget.dart';
import 'package:thingzee/pages/detail/widget/title_header_widget.dart';
import 'package:thingzee/pages/history/widget/history_list_view.dart';

class HistorySeriesListView extends StatelessWidget {
  final History history;

  const HistorySeriesListView({
    Key? key,
    required this.history,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: history.series.length,
      itemBuilder: (BuildContext context, int index) {
        final series = history.series[index];
        final entries = series.observations
            .map(
              (o) => MapEntry<int, double>(o.timestamp.toInt(), o.amount),
            )
            .toList();

        // Extract the specific regressors for this series
        final seriesIndexPattern = '-$index';
        final seriesRegressors = history.evaluator.regressors.entries
            .where((entry) => entry.key.endsWith(seriesIndexPattern))
            .map((entry) => entry.value)
            .toList();

        return Column(
          children: [
            MaterialCardWidget(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TitleHeaderWidget(
                        title: 'Series $index',
                        actionButton: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.blue),
                          onPressed: () => onDelete(index),
                        ),
                      ),
                      HistoryListView(
                        entries: entries,
                        isScrollable: false,
                      ),
                      ...seriesRegressors.map(
                        (regressor) {
                          final usageSpeedDays = regressor.hasSlope
                              ? (1 / regressor.slope.abs()) / 1000 / 60 / 60 / 24
                              : 0;
                          final accuracy =
                              history.evaluator.accuracy['${regressor.type}-$index'] ?? 0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                                'Regressor (${regressor.type}): Usage Rate (Days): ${usageSpeedDays.toStringAsFixed(2)} Accuracy: ${accuracy.toStringAsFixed(2)}'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Add a spacer between each card, but not after the last one
            if (index < history.series.length - 1) const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void onDelete(int seriesIndex) {
    // history.series.removeAt(seriesIndex);
    // history.evaluator.regressors.removeWhere((key, value) => key.endsWith('-$seriesIndex'));
    // history.evaluator.accuracy.removeWhere((key, value) => key.endsWith('-$seriesIndex'));
  }
}
