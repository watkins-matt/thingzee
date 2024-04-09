class OrderedPage {
  List<String> keys = [];

  Map<String, int> get indices {
    return Map.fromIterables(keys, List.generate(keys.length, (i) => i));
  }

  void add(String itemKey) {
    keys.add(itemKey);
  }

  bool canMerge(OrderedPage otherPage) {
    return keys.isEmpty || keys.any((item) => otherPage.keys.contains(item));
  }

  int findMergeIndex(OrderedPage otherPage) {
    Map<String, int> currentIndices = indices;

    for (int otherIndex = 0; otherIndex < otherPage.keys.length; otherIndex++) {
      final itemKey = otherPage.keys[otherIndex];

      if (currentIndices.containsKey(itemKey)) {
        int currentIndex = currentIndices[itemKey]!;

        // Check for subsequent overlapping items.
        bool allMatch = true;
        int lengthToCheck = otherPage.keys.length - otherIndex;
        for (int i = 0; i < lengthToCheck; i++) {
          int currentCheckIndex = currentIndex + i;
          int otherCheckIndex = otherIndex + i;

          // If the indices are out of range, or the items don't match, then it's not a valid overlap.
          if (currentCheckIndex >= keys.length ||
              otherCheckIndex >= otherPage.keys.length ||
              keys[currentCheckIndex] != otherPage.keys[otherCheckIndex]) {
            allMatch = false;
            break;
          }
        }

        // If all subsequent items matched, this is a valid merge index.
        if (allMatch) {
          return currentIndex;
        }
      }
    }

    return -1; // Return -1 if no valid merge index was found.
  }

  void merge(OrderedPage otherPage) {
    int mergeIndex = findMergeIndex(otherPage);

    if (mergeIndex == -1) {
      otherPage.keys.forEach(add);
    } else {
      for (final itemKey in otherPage.keys) {
        if (!keys.contains(itemKey)) {
          keys.insert(mergeIndex++, itemKey);
        }
      }
    }
  }
}

class RelativeOrderTracker {
  OrderedPage canonicalOrder = OrderedPage();
  List<OrderedPage> unmergedPages = [];

  void addPage(OrderedPage page) {
    if (page.keys.isEmpty) {
      return;
    }

    if (canonicalOrder.canMerge(page)) {
      canonicalOrder.merge(page);
    } else {
      unmergedPages.add(page);
    }

    attemptMergeUnmergedPages();
  }

  void attemptMergeUnmergedPages() {
    unmergedPages = unmergedPages.where((unmergedPage) {
      if (canonicalOrder.canMerge(unmergedPage)) {
        canonicalOrder.merge(unmergedPage);
        return false;
      }
      return true;
    }).toList();
  }
}
