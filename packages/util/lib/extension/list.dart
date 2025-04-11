extension Index on List {
  bool isValidIndex(int index) {
    return index >= 0 && index < length;
  }
}

extension ListEquals<T> on List<T> {
  bool equals(List<T> other) {
    if (identical(this, other)) return true;
    if (length != other.length) return false;
    for (var i = 0; i < length; i++) {
      if (this[i] != other[i]) return false;
    }
    return true;
  }
}

extension MapExtension<T> on List<T> {
  /// Converts a List&lt;T&gt; into a Map&lt;K, T&gt; using a keySelector
  /// function to determine the keys for each item.
  Map<K, T> toMap<K>(K Function(T) keySelector) {
    return {for (final item in this) keySelector(item): item};
  }
}

extension MedianExtension on List<double> {
  double get median {
    if (isEmpty) {
      throw StateError('Cannot find median of an empty list.');
    }

    // Create a copy of the list to avoid modifying the original
    List<double> sortedList = List.from(this)..sort();

    int middleIndex = sortedList.length ~/ 2;

    if (sortedList.length.isOdd) {
      return sortedList[middleIndex];
    } else {
      return (sortedList[middleIndex - 1] + sortedList[middleIndex]) / 2;
    }
  }
}
