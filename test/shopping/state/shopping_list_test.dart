import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/mock/repository.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:thingzee/main.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';

void main() {
  group('ShoppingList Provider Tests', () {
    late ProviderContainer container;
    late MockRepository mockRepository;

    setUp(() {
      mockRepository = MockRepository();
      mockRepository.installMockModelProvider();

      container = ProviderContainer(overrides: [
        repositoryProvider.overrideWithValue(mockRepository),
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    test('Adding a custom item without a UPC updates the shopping list', () async {
      final testItem = ShoppingItem(upc: '', name: 'Test Item', category: 'Test Category');
      final shoppingList = container.read(shoppingListProvider.notifier);

      // Initially, the list should be empty
      expect(container.read(shoppingListProvider).shoppingItems, isEmpty);

      // Add item and check if list updates
      await shoppingList.add(testItem);
      expect(container.read(shoppingListProvider).shoppingItems, contains(testItem));
    });

    test('Items that are predicted outs are added and not predicted outs are removed', () async {
      final testItemOut = ShoppingItem(upc: '1', name: 'Test Item 1', category: 'Test Category');
      final testItemNotOut = ShoppingItem(upc: '2', name: 'Test Item 2', category: 'Test Category');

      // Note that only '1' is an out
      mockRepository.inv.put(Inventory(upc: '1', amount: 0));
      expect(mockRepository.inv.outs().length, 1);

      final shoppingList = container.read(shoppingListProvider.notifier);

      // Add item and check if list updates
      await shoppingList.add(testItemNotOut);

      // We should only have testItemOut in the list
      expect(container.read(shoppingListProvider).shoppingItems, contains(testItemOut));
      expect(container.read(shoppingListProvider).shoppingItems, isNot(contains(testItemNotOut)));
      expect(container.read(shoppingListProvider).shoppingItems.length, 1);
    });

    test('Checking an item should update its status and reflect in the cart', () async {
      // Note that items without a upc will not be autoremoved. If we added
      // a upc here, it would be automatically removed unless it was an
      // out or predicted out.
      final testItem =
          ShoppingItem(upc: '', name: 'Test Item', category: 'Test Category', checked: false);
      final shoppingList = container.read(shoppingListProvider.notifier);

      // Add the item
      await shoppingList.add(testItem);

      expect(container.read(shoppingListProvider).shoppingItems, contains(testItem));
      expect(container.read(shoppingListProvider).shoppingItems.length, 1);

      // Check the item
      await shoppingList.check(testItem, true);

      final updatedItem = container
          .read(shoppingListProvider)
          .shoppingItems
          .firstWhere((item) => item.upc == testItem.upc);
      expect(updatedItem.checked, isTrue);

      // Verify it's added to the cart
      expect(container.read(shoppingListProvider).cartItems, contains(updatedItem));
    });

    test('Removing an item updates the shopping list', () async {
      final testItem = ShoppingItem(upc: '1', name: 'Test Item', category: 'Test Category');
      final shoppingList = container.read(shoppingListProvider.notifier);

      // Add the item
      await shoppingList.add(testItem);

      // Remove the item
      await shoppingList.remove(testItem);

      // Verify it's removed from the shopping list
      expect(container.read(shoppingListProvider).shoppingItems, isNot(contains(testItem)));
    });

    test('Completing a trip updates the inventory and clears the cart', () async {
      final testItem1 = ShoppingItem(upc: '1', name: 'Test Item 1', category: 'Test Category');
      final testItem2 = ShoppingItem(upc: '2', name: 'Test Item 2', category: 'Test Category');
      final testItem3 = ShoppingItem(upc: '3', name: 'Test Item 3', category: 'Test Category');

      final shoppingList = container.read(shoppingListProvider.notifier);

      // Add items to the cart
      await shoppingList.add(testItem1);
      await shoppingList.add(testItem2);
      await shoppingList.add(testItem3);

      // Complete the trip
      shoppingList.completeTrip();

      // Verify that the inventory is updated and the cart is cleared
      expect(container.read(shoppingListProvider).cartItems, isEmpty);
    });
  });
}
