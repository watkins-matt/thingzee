import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:thingzee/icon_library.dart';
import 'package:thingzee/pages/barcode/barcode_scanner_page.dart';
import 'package:thingzee/pages/inventory/filter_dialog.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/inventory/widget/inventory_view_widget.dart';
import 'package:thingzee/pages/inventory/widget/user_profile_button.dart';
import 'package:thingzee/pages/settings/settings_page.dart';

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
  void initState() {
    _controller = FloatingSearchBarController();
    super.initState();
  }

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
          // IconButton(
          //   icon: gridView ? const Icon(Icons.view_list) : const Icon(Icons.grid_view),
          //   onPressed: () {
          //     setState(() {
          //       gridView = !gridView;
          //     });
          //   },
          // ),
          FilterButton(key: GlobalKey()),
          UserProfileButton(
            imagePath: 'assets/images/account.png',
            onSelected: (String value) async {
              if (value == 'Settings') {
                await SettingsPage.push(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Manually Add Item', 'Login', 'Register', 'Settings'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
        body:
            const InventoryViewWidget() /*gridView ? const InventoryGridViewWidget() : const InventoryViewWidget()*/
        ,
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
          // Reset the Barcode scanner state

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
}

class FilterButton extends ConsumerWidget {
  const FilterButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
        icon: const Icon(Icons.filter_list),
        onPressed: () async {
          final view = ref.read(inventoryProvider.notifier);

          final filterResult = await FilterDialog.show(context, view.filter);
          view.filter = filterResult;

          await view.refresh();
        });
  }
}
