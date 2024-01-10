import 'package:repository/ml/evaluator.dart';
import 'package:repository/ml/history.dart';

class EvaluatorProvider {
  static final EvaluatorProvider _instance = EvaluatorProvider._internal();
  final Map<String, Evaluator> _evaluators = {};

  factory EvaluatorProvider() {
    return _instance;
  }

  EvaluatorProvider._internal();

  Evaluator getEvaluator(String upc, History newHistory) {
    final existingEvaluator = _evaluators[upc];
    if (existingEvaluator != null) {
      // Check if the existing history is equivalent to the new one
      if (!existingEvaluator.history.equalTo(newHistory)) {
        // If not equivalent, update the history and retrain the evaluator
        existingEvaluator.history = newHistory;
        existingEvaluator.train(newHistory);
      }
      // Return the existing evaluator if the histories are equivalent
      return existingEvaluator;
    } else {
      // Create a new evaluator if one doesn't exist for this UPC
      final newEvaluator = Evaluator(newHistory);
      _evaluators[upc] = newEvaluator;
      newEvaluator.train(newHistory);
      return newEvaluator;
    }
  }
}
