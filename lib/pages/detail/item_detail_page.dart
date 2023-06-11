import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:stats/double.dart';
import 'package:thingzee/app.dart';
import 'package:thingzee/pages/detail/state/editable_item.dart';
import 'package:thingzee/pages/history/widget/history_list_view.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';

extension SelectAllExtension on TextEditingController {
  void selectAll() {
    if (text.isEmpty) return;
    selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }
}

class ItemDetailPage extends HookConsumerWidget {
  final Item item;
  const ItemDetailPage(this.item, {Key? key}) : super(key: key);

  static Future<void> push(
    BuildContext context,
    WidgetRef ref,
    Item item,
    Inventory inventory,
  ) async {
    final itemProv = ref.watch(editableItemProvider.notifier);
    itemProv.copyFrom(item, inventory);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ItemDetailPage(item)),
    );
  }

  Future<bool> onBackButtonPressed(BuildContext context, WidgetRef ref) async {
    // Make sure we refresh the inventory
    final view = ref.read(inventoryProvider.notifier);
    await view.refresh();

    return true;
  }

  Future<void> onSaveButtonPressed(BuildContext context, WidgetRef ref) async {
    final editableItem = ref.read(editableItemProvider.notifier);
    editableItem.save(App.repo);

    final view = ref.read(inventoryProvider.notifier);
    await view.refresh();

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editableItem = ref.watch(editableItemProvider.notifier);
    final amountController = useTextEditingController(text: editableItem.amount.toStringNoZero(2));
    final unitController = useTextEditingController(text: editableItem.unitCount.toString());
    final totalUnitController =
        useTextEditingController(text: editableItem.totalUnitCount.toStringNoZero(2));
    final nameController = useTextEditingController(text: editableItem.name);
    final upcController = useTextEditingController(text: editableItem.upc);
    //final predictedAmountController = useTextEditingController(text: editableItem.predictedAmount);

    final cache = ref.watch(itemThumbnailCache);
    Image? image;

    if (item.imageUrl.isNotEmpty && cache.containsKey(item.upc) && cache[item.upc] != null) {
      image = cache[item.upc]!;
    } else {
      image = const Image(
        image: AssetImage('assets/images/no_image_available.png'),
        width: 100,
        height: 100,
      );
    }

    return WillPopScope(
      onWillPop: () async => onBackButtonPressed(context, ref),
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 120,
          leading: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.cancel_outlined),
              onPressed: () {
                Navigator.pop(context);
              },
              label: const Text('Cancel'),
            ),
          ),
          actions: <Widget>[
            TextButton.icon(
                onPressed: () async => onSaveButtonPressed(context, ref),
                icon: const Icon(Icons.check),
                label: const Text(
                  'Save',
                ))
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 35,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: InkWell(
                              onTap: () async {
                                // String result = await ImageBrowserPage.push(context, name.text.trim());
                                // setState(() {
                                //   imageUrl = Optional.fromNullable(result);
                                // });
                              },
                              child: image,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 65,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            TextField(
                                decoration: const InputDecoration(
                                    border: InputBorder.none, isCollapsed: true),
                                textAlign: TextAlign.left,
                                keyboardType: TextInputType.text,
                                textCapitalization: TextCapitalization.words,
                                controller: nameController,
                                onTap: () {
                                  if (nameController.text == 'Unknown Item') {
                                    nameController.selectAll();
                                  }
                                },
                                onChanged: (value) {
                                  ref.read(editableItemProvider.notifier).name = value;
                                },
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
                                minLines: 1,
                                maxLines: null),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Visibility(
                  // visible: widget.product.canPredictAmount,
                  visible: true,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Divider(
                      thickness: 2,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Padding(
                            padding: EdgeInsets.all(4),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'UPC',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(border: InputBorder.none, isCollapsed: true),
                            textAlign: TextAlign.left,
                            controller: upcController,
                            onChanged: (value) {
                              ref.read(editableItemProvider.notifier).upc = value;
                            },
                            minLines: 1,
                            maxLines: null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Padding(
                            padding: EdgeInsets.all(4),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Last Updated',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            ref.read(editableItemProvider).inventory.timeSinceLastUpdateString,
                            textScaleFactor: 0.9,
                            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Divider(
                    thickness: 2,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Visibility(
                    visible: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SizedBox(
                          width: 100,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Predicted',
                              ),
                              TextField(
                                decoration: const InputDecoration(border: InputBorder.none),
                                textAlign: TextAlign.center,
                                controller: TextEditingController(
                                    text: ref.watch(editableItemProvider.notifier).predictedAmount),
                                readOnly: true,
                                maxLines: null,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Usage (Days)',
                              ),
                              TextField(
                                decoration: const InputDecoration(border: InputBorder.none),
                                textAlign: TextAlign.center,
                                controller: TextEditingController(
                                    text:
                                        '3.0'), // widget.product.usageSpeedDays.toStringAsFixed(2)),
                                readOnly: true,
                                maxLines: null,
                              ),
                            ],
                          ),
                        ),
                        // SizedBox(
                        //   width: 100,
                        //   child: Column(
                        //     mainAxisSize: MainAxisSize.min,
                        //     crossAxisAlignment: CrossAxisAlignment.center,
                        //     children: [
                        //       Text(
                        //         'Usage (Minutes)',
                        //       ),
                        //       TextField(
                        //         decoration: InputDecoration(border: InputBorder.none),
                        //         textAlign: TextAlign.center,
                        //         controller: TextEditingController(
                        //             text: widget.product.usageSpeedMinutes.roundTo(2).toString()),
                        //         readOnly: true,
                        //         maxLines: null,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        SizedBox(
                          width: 100,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Out Date',
                              ),
                              TextField(
                                decoration: const InputDecoration(border: InputBorder.none),
                                textAlign: TextAlign.center,
                                controller: TextEditingController(
                                    text: '9/9/2023'), //widget.product.predictedOutDateString),
                                readOnly: true,
                                maxLines: null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Divider(
                    thickness: 2,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Quantity',
                          ),
                          TextField(
                            decoration: const InputDecoration(border: InputBorder.none),
                            textAlign: TextAlign.center,
                            controller: amountController,
                            onChanged: (value) {
                              double? doubleValue = double.tryParse(value);
                              if (doubleValue != null) {
                                ref.read(editableItemProvider.notifier).amount = doubleValue;

                                final editableItem = ref.read(editableItemProvider.notifier);
                                totalUnitController.text =
                                    editableItem.totalUnitCount.toStringNoZero(2);
                              } else {
                                // TODO: Show validation error
                              }
                            },
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Unit Count',
                          ),
                          TextField(
                              decoration: const InputDecoration(border: InputBorder.none),
                              textAlign: TextAlign.center,
                              controller: unitController,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                int? intValue = int.tryParse(value);
                                if (intValue != null) {
                                  // Update the unit count
                                  ref.read(editableItemProvider.notifier).unitCount = intValue;

                                  // Update the total unit count
                                  final editableItem = ref.read(editableItemProvider.notifier);
                                  totalUnitController.text =
                                      editableItem.totalUnitCount.toStringNoZero(2);
                                } else {
                                  // TODO: Validation error
                                }
                              }),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Total Units',
                          ),
                          TextField(
                            decoration: const InputDecoration(border: InputBorder.none),
                            textAlign: TextAlign.center,
                            controller: totalUnitController,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              double? totalUnitDouble = double.tryParse(value);

                              if (totalUnitDouble != null) {
                                double unitCount =
                                    ref.read(editableItemProvider.notifier).unitCount.toDouble();

                                double quantity = totalUnitDouble / unitCount;

                                // Update the amount
                                ref.read(editableItemProvider.notifier).amount = quantity;

                                // Update the amount text field
                                amountController.text = quantity.toStringNoZero(2);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Divider(
                    thickness: 2,
                  ),
                ),
                HistoryListView(
                    entries: ref.watch(editableItemProvider.notifier).allHistoryEntries,
                    isScrollable: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
