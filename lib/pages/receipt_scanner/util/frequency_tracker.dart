class FrequencyTracker<T> {
  Map<T, int> frequencies = {};

  void add(T item) {
    frequencies.update(item, (count) => count + 1, ifAbsent: () => 1);
  }

  T? getMostFrequent() {
    if (frequencies.isEmpty) return null;
    return frequencies.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  List<T> getMostFrequentList() {
    if (frequencies.isEmpty) return [];

    double averageFrequency = frequencies.values.reduce((a, b) => a + b) / frequencies.length;
    double threshold = averageFrequency * 0.5;

    return frequencies.entries
        .where((entry) => entry.value > threshold)
        .map((entry) => entry.key)
        .toList();
  }

  @override
  String toString() {
    return '${getMostFrequent()}';
  }
}
