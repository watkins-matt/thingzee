import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:stats/double.dart';
import 'package:thingzee/app.dart';
import 'package:thingzee/pages/detail/state/editable_item.dart';
import 'package:thingzee/pages/detail/widget/item_header_widget.dart';
import 'package:thingzee/pages/detail/widget/labeled_editable_text.dart';
import 'package:thingzee/pages/detail/widget/labeled_switch_widget.dart';
import 'package:thingzee/pages/detail/widget/labeled_text.dart';
import 'package:thingzee/pages/detail/widget/material_card_widget.dart';
import 'package:thingzee/pages/detail/widget/text_field_column_widget.dart';
import 'package:thingzee/pages/detail/widget/title_header_widget.dart';
import 'package:thingzee/pages/history/widget/history_list_view.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';

class ItemDetailPage extends HookConsumerWidget {
  final Item item;
  const ItemDetailPage(this.item, {Key? key}) : super(key: key);

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
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
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
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ItemHeaderWidget(
                  image: image,
                  nameController: nameController,
                  imageOnTap: () {},
                  onChanged: (value) {
                    ref.read(editableItemProvider.notifier).name = value;
                  },
                ),
                const SizedBox(
                  height: 8,
                ),
                MaterialCardWidget(children: [
                  const TitleHeaderWidget(
                      title: 'Identifiers',
                      actionButton:
                          IconButton(onPressed: null, icon: Icon(Icons.add, color: Colors.blue))),
                  LabeledEditableText(
                    labelText: 'UPC',
                    keyboardType: TextInputType.number,
                    controller: upcController,
                    onChanged: (value) {
                      ref.read(editableItemProvider.notifier).upc = value;
                    },
                  ),
                  // ChoiceBoxEditableText(
                  //     choices: const ['UPC', 'EAN'],
                  //     keyboardType: TextInputType.number,
                  //     controller: useTextEditingController(),
                  //     onChanged: (value) {}),
                ]),
                const SizedBox(
                  height: 8,
                ),
                MaterialCardWidget(children: [
                  const TitleHeaderWidget(title: 'Details'),
                  LabeledText(
                    labelText: 'Last Updated',
                    value: ref.read(editableItemProvider).inventory.timeSinceLastUpdateString,
                  ),
                  LabeledSwitchWidget(
                      labelText: 'Consumable',
                      value: ref.watch(editableItemProvider.notifier).consumable,
                      onChanged: (value) {
                        ref.read(editableItemProvider.notifier).consumable = value;
                      }),
                ]),
                const SizedBox(
                  height: 8,
                ),
                MaterialCardWidget(children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: TitleHeaderWidget(title: 'Inventory'),
                  ),
                  Visibility(
                    visible: ref.read(editableItemProvider).inventory.canPredict,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        TextFieldColumnWidget(
                          labelText: 'Predicted',
                          controller: TextEditingController(
                            text: ref.watch(editableItemProvider.notifier).predictedAmount,
                          ),
                          readOnly: true,
                        ),
                        TextFieldColumnWidget(
                          labelText: 'Usage (Days)',
                          controller: TextEditingController(
                            text: ref
                                .watch(editableItemProvider)
                                .inventory
                                .usageSpeedDays
                                .roundTo(2)
                                .toString(),
                          ),
                          readOnly: true,
                        ),
                        TextFieldColumnWidget(
                          labelText: 'Out Date',
                          controller: TextEditingController(
                            text: ref.watch(editableItemProvider).inventory.predictedOutDateString,
                          ),
                          readOnly: true,
                        ),
                      ],
                    ),
                  ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        TextFieldColumnWidget(
                          labelText: 'Quantity',
                          controller: amountController,
                          inputFormat: r'^\d*\.?\d*',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) {
                            double? doubleValue = double.tryParse(value);
                            if (doubleValue != null) {
                              ref.read(editableItemProvider.notifier).amount = doubleValue;

                              final editableItem = ref.read(editableItemProvider.notifier);
                              totalUnitController.text =
                                  editableItem.totalUnitCount.toStringNoZero(2);
                            }
                          },
                        ),
                        TextFieldColumnWidget(
                            labelText: 'Unit Count',
                            controller: unitController,
                            inputFormat: r'^\d*',
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
                        TextFieldColumnWidget(
                          labelText: 'Total Units',
                          controller: totalUnitController,
                          inputFormat: r'^\d*\.?\d*',
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
                      ]),
                ]),
                const SizedBox(
                  height: 8,
                ),
                MaterialCardWidget(children: [
                  const TitleHeaderWidget(title: 'History'),
                  HistoryListView(
                      entries: ref.watch(editableItemProvider.notifier).allHistoryEntries,
                      isScrollable: false),
                ]),
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

    final shoppingList = ref.read(shoppingListProvider.notifier);
    shoppingList.refresh();

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

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
}
