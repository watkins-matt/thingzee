import 'package:fuzzy/fuzzy.dart';
import 'package:repository/model/item.dart';

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
      threshold: 0.3,
      isCaseSensitive: false,
    );

    // Initialize Fuzzy with the list of item names.
    final fuzzy = Fuzzy(itemNames, options: options);

    // Perform the search.
    final result = fuzzy.search(query);

    // Prepare a map for quick lookup from item name to a list of items.
    Map<String, List<T>> nameToItemsMap = {};
    for (final item in allItems) {
      nameToItemsMap.putIfAbsent(item.name, () => []).add(item);
    }

    // Map the results back to items using the item name for lookup.
    List<T> matchedItems = [];
    for (final r in result) {
      String matchedName = r.item; // The matched item name.
      // Check if the matched name exists in the map and add all corresponding items to the results.
      List<T>? items = nameToItemsMap[matchedName];
      if (items != null) {
        matchedItems.addAll(items);
      }
    }

    return matchedItems;
  }
}
