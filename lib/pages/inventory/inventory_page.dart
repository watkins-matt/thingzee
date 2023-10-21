import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:thingzee/icon_library.dart';
import 'package:thingzee/pages/barcode/barcode_scanner_page.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/inventory/widget/filter_button.dart';
import 'package:thingzee/pages/inventory/widget/inventory_view_widget.dart';
import 'package:thingzee/pages/inventory/widget/user_profile_button.dart';
import 'package:thingzee/pages/inventory/widget/view_button.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  late final FloatingSearchBarController _controller;
  bool gridView = false;
  bool hasQuery = false;

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(inventoryProvider.notifier);
    final products = ref.watch(inventoryProvider);

    int count = products.length;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: FloatingSearchBar(
        hint: count > 0 ? 'Search $count items...' : 'Search...',
        isScrollControlled: true,
        borderRadius: BorderRadius.circular(30),
        clearQueryOnClose: false,
        automaticallyImplyBackButton: false,
        margins:
            EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top + 10, left: 10, right: 10),
        actions: [
          Visibility(
              visible: hasQuery,
              child: IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () {
                  setState(() {
                    _controller.query = '';
                  });
                },
              )),
          FilterButton(key: GlobalKey()),
          ViewButton(key: GlobalKey()),
          const UserProfileButton(imagePath: 'assets/images/account.png'),
        ],
        body: const InventoryViewWidget(),
        builder: (BuildContext context, Animation<double> transition) {
          return const SizedBox(
            width: 0,
            height: 0,
          );
        },
        onQueryChanged: (query) async {
          hasQuery = query.isNotEmpty;
          await view.search(query);
          setState(() {});
        },
        backdropColor: Colors.black26,
        controller: _controller,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'InventoryBarcodeScan',
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const BarcodeScannerPage(BarcodeScannerMode.showItemDetail)),
          );
        },
        tooltip: 'Scan Barcode',
        child: const Icon(IconLibrary.barcode),
      ),
    );
  }

  @override
  void initState() {
    _controller = FloatingSearchBarController();
    super.initState();
  }
}
