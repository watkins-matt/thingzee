import 'package:flutter/material.dart';
import 'package:repository/ml/history.dart';
import 'package:thingzee/pages/detail/widget/material_card_widget.dart';
import 'package:thingzee/pages/detail/widget/title_header_widget.dart';
import 'package:thingzee/pages/history/widget/history_list_view.dart';
import 'package:thingzee/pages/history/widget/regressor_view_widget.dart';

class HistorySeriesListView extends StatelessWidget {
  final History history;
  final Function(int) onDeleteSeries;

  const HistorySeriesListView({
    Key? key,
    required this.history,
    required this.onDeleteSeries,
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

        // Determine if this series is an outlier
        final isOutlier = history.evaluator.outlierSeriesIndices.contains(index);

        return Dismissible(
          key: UniqueKey(),
          background: Container(color: Colors.red),
          onDismissed: (direction) => onDeleteSeries(index),
          child: Column(
            children: [
              MaterialCardWidget(
                children: [
                  Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: TitleHeaderWidget(
                                title: 'Series $index',
                              ),
                            ),
                            if (isOutlier)
                              const Text(
                                'Outlier Series',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        HistoryListView(
                          entries: entries,
                          isScrollable: false,
                        ),
                        Visibility(
                          visible: seriesRegressors.isNotEmpty,
                          child: RegressorViewWidget(
                            seriesRegressors: seriesRegressors,
                            evaluatorAccuracy: history.evaluator.accuracy,
                            index: index,
                          ),
                        )
                      ]))
                ],
              ),
              // Add a spacer between each card, but not after the last one
              if (index < history.series.length - 1) const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
