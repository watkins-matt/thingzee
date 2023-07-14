import 'package:flutter/material.dart';
import 'package:thingzee/pages/inventory/inventory_page.dart';
import 'package:thingzee/pages/recipe_browser/recipe_browser.dart';
import 'package:thingzee/pages/shopping/shopping_list_page.dart';

class HomePage extends StatefulWidget {
  static int index = 0;
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Widget> pageList = [
    const InventoryPage(),
    Container(), // const LocationPage(),
    const RecipeBrowser(),
    const ShoppingListPage(),
  ];

  Widget auditIcon() {
    //   return Badge(
    //       showBadge: manager.hasUncompleted,
    //       toAnimate: false,
    //       position: BadgePosition.topEnd(top: -15, end: -15),
    //       badgeContent: Text(manager.uncompleted.toString()),
    //       child: Icon(Icons.playlist_add_check));
    // );
    return const Icon(Icons.playlist_add_check);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: _bottomNavBar(),
        body: IndexedStack(
          index: HomePage.index,
          children: pageList,
        ));
  }

  void itemSelected(int newIndex) {
    if (HomePage.index == newIndex) {
      return; // Don't reload the current page
    }

    setState(() {
      HomePage.index = newIndex;
    });
  }

  Widget _bottomNavBar() {
    return BottomNavigationBar(
        onTap: itemSelected,
        currentIndex: HomePage.index,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Locations'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Recipes'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Shopping List')
        ]);
  }
}
