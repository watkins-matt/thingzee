import 'package:fuzzy/fuzzy.dart';
import 'package:log/log.dart';
import 'package:repository/model/abstract/nameable.dart';

mixin FuzzySearchable<T extends Nameable> {
  List<T> all();

  List<T> fuzzySearch(String query) {
    List<T> allItems = all();

    // If the query is empty, return all items.
    if (query.isEmpty) {
      return allItems;
    }

    // Prepare the list of names for fuzzy searching.
    List<String> itemNames = allItems.map((e) => e.name).toList();

    final options = FuzzyOptions(
      findAllMatches: true,
      threshold: 0.1,
      isCaseSensitive: false,
      tokenize: true,
      maxPatternLength: 64,
    );

    // Initialize Fuzzy with the list of item names.
    final fuzzy = Fuzzy(itemNames, options: options);

    // Perform the search.
    final result = fuzzy.search(query);

    List<T> matchedItems = [];
    for (final item in result) {
      final index = item.matches.first.arrayIndex;

      if (index < allItems.length) {
        matchedItems.add(allItems[index]);
      } else {
        Log.w('fuzzySearch: Index out of bounds: $index, length: ${allItems.length}');
      }
    }

    return matchedItems;
  }
}
