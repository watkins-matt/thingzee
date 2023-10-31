import 'package:flutter/material.dart';
import 'package:repository/ml/regressor.dart';

class RegressorViewWidget extends StatelessWidget {
  final List<Regressor> seriesRegressors;
  final Map<String, double> evaluatorAccuracy;
  final int index;

  const RegressorViewWidget({
    Key? key,
    required this.seriesRegressors,
    required this.evaluatorAccuracy,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  'Regressor',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Usage Rate (Days)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Accuracy',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        ...seriesRegressors.map(
          (regressor) {
            final usageRateDays = regressor.usageRateDays;
            final accuracy = evaluatorAccuracy['${regressor.type}-$index'] ?? 0;

            return Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      regressor.type,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      usageRateDays.toStringAsFixed(2),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${accuracy.toStringAsFixed(0)}%',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
