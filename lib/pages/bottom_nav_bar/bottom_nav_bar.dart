import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/bottom_nav_bar/state/bottom_nav_state.dart';
import 'package:thingzee/pages/inventory/inventory_page.dart';
import 'package:thingzee/pages/location/location_page.dart';
import 'package:thingzee/pages/recipe_browser/recipe_browser.dart';
import 'package:thingzee/pages/shopping/shopping_list_page.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavBarIndexProvider);

    List<Widget> pageList = [
      const InventoryPage(),
      const LocationPage(),
      const RecipeBrowser(),
      const ShoppingListPage(),
    ];

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        onTap: (newIndex) {
          if (currentIndex == newIndex) {
            return; // Don't reload the current page
          }
          ref.read(bottomNavBarIndexProvider.notifier).state = newIndex;
        },
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Locations'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Recipes'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Shopping List'),
        ],
      ),
      body: IndexedStack(
        index: currentIndex,
        children: pageList,
      ),
    );
  }
}
