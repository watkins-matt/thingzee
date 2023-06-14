import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/icon_library.dart';
import 'package:thingzee/pages/barcode/barcode_scanner_page.dart';
import 'package:thingzee/pages/shopping/state/shopping_cart.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({Key? key}) : super(key: key);

  static Future<void> push(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShoppingListPage()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sl = ref.watch(shoppingListProvider);
    final sc = ref.watch(shoppingCartProvider);

    return Scaffold(
      drawer: const Drawer(),
      appBar: AppBar(
        // elevation: 0,
        actions: [
          TextButton.icon(
              onPressed: () async {
                // TODO: Open shopping cart page
                //await ShoppingCartPage.push(context);
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('View Cart'))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) => shoppingListItemBuilder(context, ref, index, sl, sc),
              itemCount: sl.items.length,
            ),
          )
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // FloatingActionButton(
          //     onPressed: () {}, heroTag: 'ShoppingListAdd', child: Icon(Icons.add)),
          // SizedBox(
          //   height: 15,
          //   // width: 50,
          // ),
          FloatingActionButton(
            heroTag: 'ShoppingListBarcodeScan',
            onPressed: () async {
              await BarcodeScannerPage.push(context, BarcodeScannerMode.addToShoppingList);
            },
            tooltip: 'Scan Barcode',
            child: const Icon(IconLibrary.barcode),
          ),
        ],
      ),
    );
  }

  Widget shoppingListItemBuilder(
      BuildContext context, WidgetRef ref, int index, ShoppingListState sl, ShoppingCartState sc) {
    final item = sl.items[index];

    return InkWell(
      onLongPress: () async {
        // await ItemDetailPage.push(context, item);
      },
      child: Dismissible(
        key: UniqueKey(),
        onDismissed: (_) {
          ref.read(shoppingListProvider.notifier).removeAt(index);
          ref.read(shoppingCartProvider.notifier).remove(item);
        },
        child: CheckboxListTile(
          value: sl.checked.contains(item.upc),
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (value) {
            ref.read(shoppingListProvider.notifier).check(index, value ?? false);

            if (sl.checked.contains(item.upc)) {
              ref.read(shoppingCartProvider.notifier).add(item);
            } else {
              ref.read(shoppingCartProvider.notifier).remove(item);
            }
          },
          title: Text(
            item.name,
            style: TextStyle(
              decoration:
                  sl.checked.contains(item.upc) ? TextDecoration.lineThrough : TextDecoration.none,
            ),
          ),
          subtitle:
              // TODO: Should display the predicted out date
              // item.canPredictAmount
              //     ? Text('Out on ${DateFormat.yMMMd().format(item.predictedOutDate)}',
              //         style: TextStyle(
              //             decoration: sl.checked[item.upc] == true
              //                 ? TextDecoration.lineThrough
              //                 : TextDecoration.none)) :
              null,
          secondary: const Text(
            // TODO: Fix placeholder value
            '0.0', //item.preferredPredictedUnitString,
            textScaleFactor: 1.5,
            style: TextStyle(
                color: Colors
                    .red), //TextStyle(color: item.predictedAmount > 0.5 ? Colors.green : Colors.red),
          ),
        ),
      ),
    );
  }
}
