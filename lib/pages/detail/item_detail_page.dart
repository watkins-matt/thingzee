import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:stats/double.dart';
import 'package:thingzee/app.dart';
import 'package:thingzee/pages/detail/state/editable_item.dart';
import 'package:thingzee/pages/detail/widget/labeled_editable_text.dart';
import 'package:thingzee/pages/detail/widget/labeled_text.dart';
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
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Divider(
                    thickness: 2,
                  ),
                ),
                Column(
                  children: [
                    LabeledEditableText(
                      labelText: 'UPC',
                      keyboardType: TextInputType.number,
                      controller: upcController,
                      onChanged: (value) {
                        ref.read(editableItemProvider.notifier).upc = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    LabeledText(
                      labelText: 'Last Updated',
                      value: ref.read(editableItemProvider).inventory.timeSinceLastUpdateString,
                    ),
                  ],
                ),
                Visibility(
                  visible: ref.read(editableItemProvider).inventory.canPredict,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Divider(
                      thickness: 2,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Visibility(
                    visible: ref.read(editableItemProvider).inventory.canPredict,
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
                                    text: ref
                                        .watch(editableItemProvider)
                                        .inventory
                                        .usageSpeedDays
                                        .roundTo(2)
                                        .toString()),
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
                                'Out Date',
                              ),
                              TextField(
                                decoration: const InputDecoration(border: InputBorder.none),
                                textAlign: TextAlign.center,
                                controller: TextEditingController(
                                  text: ref
                                      .watch(editableItemProvider)
                                      .inventory
                                      .predictedOutDateString,
                                ),
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
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            onChanged: (value) {
                              double? doubleValue = double.tryParse(value);
                              if (doubleValue != null) {
                                ref.read(editableItemProvider.notifier).amount = doubleValue;

                                final editableItem = ref.read(editableItemProvider.notifier);
                                totalUnitController.text =
                                    editableItem.totalUnitCount.toStringNoZero(2);
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
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*')),
                              ],
                              controller: unitController,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                int? intValue = int.tryParse(value);
                                if (intValue != null && intValue > 0) {
                                  // Update the unit count
                                  ref.read(editableItemProvider.notifier).unitCount = intValue;

                                  // Update the total unit count
                                  final editableItem = ref.read(editableItemProvider.notifier);
                                  totalUnitController.text =
                                      editableItem.totalUnitCount.toStringNoZero(2);
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
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
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
                // const Padding(
                //   padding: EdgeInsets.all(8),
                //   child: Divider(
                //     thickness: 2,
                //   ),
                // ),
                // TextButton(
                //     onPressed: () async {
                //       ref.read(editableItemProvider.notifier).cleanUpHistory(App.repo);
                //       final view = ref.read(inventoryProvider.notifier);
                //       await view.refresh();
                //     },
                //     child: const Text('Clean Up History'))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
