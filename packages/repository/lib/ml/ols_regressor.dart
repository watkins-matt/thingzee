import 'package:ml_dataframe/ml_dataframe.dart';
import 'package:ml_linalg/dtype.dart';
import 'package:ml_linalg/matrix.dart';
import 'package:ml_linalg/vector.dart';

class OLSRegressor {
  late Vector _coefficients;
  late String _target;

  void fit(DataFrame df, String target) {
    final X = Matrix.fromColumns([
      Vector.filled(df.rows.length, 1.0,
          dtype: DType.float64), // A column of ones for the intercept
      ...df.dropSeries(names: [target]).toMatrix(DType.float64).columns,
    ]);

    final y = Vector.fromList(df[target].data.cast<double>().toList(), dtype: DType.float64);
    final coefficientMatrix = (X.transpose() * X).inverse() * X.transpose() * y;

    _coefficients = coefficientMatrix.toVector();
    _target = target;
  }

  double predict(DataFrame df) {
    // Remove the target column if it exists
    df = df.header.contains(_target) ? df.dropSeries(names: [_target]) : df;

    // Create a new matrix with a column of ones for the intercept
    final X = Matrix.fromColumns([
      Vector.filled(1, 1.0, dtype: DType.float64),
      ...df.toMatrix(DType.float64).columns,
    ]);

    return (X * _coefficients).sum();
  }
}
