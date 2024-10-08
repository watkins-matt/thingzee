import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:repository/database/joined_item_database.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:repository/model/location.dart';
import 'package:thingzee/main.dart';
import 'package:thingzee/pages/detail/state/editable_item.dart';
import 'package:thingzee/pages/detail/widget/item_header_widget.dart';
import 'package:thingzee/pages/detail/widget/labeled_editable_text.dart';
import 'package:thingzee/pages/detail/widget/labeled_switch_widget.dart';
import 'package:thingzee/pages/detail/widget/labeled_text.dart';
import 'package:thingzee/pages/detail/widget/location_chip_view.dart';
import 'package:thingzee/pages/detail/widget/location_selection_dialog.dart';
import 'package:thingzee/pages/detail/widget/material_card_widget.dart';
import 'package:thingzee/pages/detail/widget/text_field_column_widget.dart';
import 'package:thingzee/pages/detail/widget/title_header_widget.dart';
import 'package:thingzee/pages/detail/widget/url_input_dialog.dart';
import 'package:thingzee/pages/history/history_page.dart';
import 'package:thingzee/pages/history/widget/history_list_view.dart';
import 'package:thingzee/pages/image_browser/image_browser_page.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';
import 'package:thingzee/pages/settings/state/settings_state.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';
import 'package:util/extension/double.dart';
import 'package:util/extension/uuid.dart';

class ItemDetailPage extends HookConsumerWidget {
  final Item item;
  const ItemDetailPage(this.item, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editableItem = ref.watch(editableItemProvider.notifier);
    final amountController = useTextEditingController(text: editableItem.amount.toStringNoZero(2));
    final unitController = useTextEditingController(text: editableItem.unitCount.toString());
    final totalUnitController =
        useTextEditingController(text: editableItem.totalUnitCount.toStringNoZero(2));
    final nameController = useTextEditingController(text: editableItem.name);
    final upcController = useTextEditingController(text: editableItem.upc);
    final typeController = useTextEditingController(text: editableItem.type);
    List<String> locations = ref.watch(editableItemProvider.notifier).locations;
    final isDarkMode = ref.watch(isDarkModeProvider(context));

    // For every location, pretty print it
    locations = locations.map((e) => prettyPrintPath(e)).toList();

    final cache = ref.watch(itemThumbnailCache);
    Image? image;

    if (editableItem.imageUrl.isNotEmpty &&
        cache.containsKey(editableItem.upc) &&
        cache[editableItem.upc] != null) {
      image = cache[editableItem.upc]!;
    } else {
      image = const Image(
        image: AssetImage('assets/images/no_image_available.png'),
        width: 100,
        height: 100,
      );
    }

    List<LabeledEditableText> identifierWidgets = [];
    for (final identifier in editableItem.identifiers.entries) {
      identifierWidgets.add(LabeledEditableText(
        labelText: identifier.key,
        keyboardType: TextInputType.number,
        controller: useTextEditingController(text: identifier.value),
        onChanged: (value) {
          ref.read(editableItemProvider.notifier).updateIdentifier(identifier.key, value);
        },
      ));
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (pop, result) async => onBackButtonPressed(context, ref),
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
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ItemHeaderWidget(
                    image: image,
                    nameController: nameController,
                    onImagePressed: () async => await onImagePressed(context, ref),
                    onNameChanged: (value) {
                      ref.read(editableItemProvider.notifier).name = value;
                    },
                    isDarkMode: isDarkMode),
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
                                .usageRateDays
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
                MaterialCardWidget(
                  children: [
                    TitleHeaderWidget(
                        title: 'Locations',
                        actionButton: IconButton(
                          onPressed: () async => await onAddLocationPressed(context, ref),
                          icon: const Icon(Icons.add, color: Colors.blue),
                        )),
                    LocationChipView(
                      locations: locations.toSet(),
                      onLocationRemove: (location) {
                        ref.read(editableItemProvider.notifier).removeLocation(location);
                      },
                    )
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                MaterialCardWidget(children: [
                  TitleHeaderWidget(
                      title: 'Identifiers',
                      actionButton: IconButton(
                          onPressed: () async => await onAddIdentifierButtonPressed(context, ref),
                          icon: const Icon(Icons.add, color: Colors.blue))),
                  LabeledText(
                    labelText: 'UID',
                    value: editableItem.uid.abbreviatedUuid,
                    valueTextStyle: const TextStyle(
                        fontStyle: FontStyle.normal, fontSize: 16, color: Colors.blue),
                  ),
                  LabeledEditableText(
                    labelText: 'UPC',
                    keyboardType: TextInputType.number,
                    controller: upcController,
                    onChanged: (value) {
                      ref.read(editableItemProvider.notifier).upc = value;
                    },
                  ),
                  ...identifierWidgets,
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
                  LabeledEditableText(
                    labelText: 'Item Type',
                    keyboardType: TextInputType.text,
                    controller: typeController,
                    onChanged: (value) {
                      ref.read(editableItemProvider.notifier).type = value;
                    },
                    helpTooltip: 'A generic, unbranded name for what the item is. '
                        'For example, "Milk" or "Bread". Do not include '
                        'brand names or other details like scents, flavors '
                        'or packaging/size information.',
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
                  TitleHeaderWidget(
                      title: 'History',
                      actionButton: IconButton(
                          onPressed: () async => await onCleanUpHistory(ref),
                          icon: const Icon(Icons.cleaning_services, color: Colors.blue))),
                  HistoryListView(
                      entries: ref.watch(editableItemProvider.notifier).currentHistorySeries,
                      isScrollable: false),
                  Center(
                      child: TextButton(
                          child: const Text('View Full History Detail'),
                          onPressed: () async => onHistoryDetailPressed(context, ref))),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> onAddIdentifierButtonPressed(BuildContext context, WidgetRef ref) async {
    // Retrieve the list of unused identifier types from the provider
    final validIdentifierTypes = ref.watch(editableItemProvider.notifier).unusedIdentifierTypes;

    // Show a dialog or a bottom sheet to let the user pick an identifier type
    final String? selectedType = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: validIdentifierTypes.map((type) {
              return ListTile(
                leading: const Icon(Icons.label),
                title: Text(type),
                onTap: () => Navigator.of(context).pop(type),
              );
            }).toList(),
          ),
        );
      },
    );

    // Add the identifier selected by the user
    if (selectedType != null) {
      ref.read(editableItemProvider.notifier).addIdentifier(selectedType);
    }
  }

  Future<bool> onAddLocationPressed(BuildContext context, WidgetRef ref) async {
    final result = await LocationSelectorDialog.show(context);
    if (result.isNotEmpty) {
      ref.read(editableItemProvider.notifier).addLocation(result);
    }
    return true;
  }

  Future<bool> onBackButtonPressed(BuildContext context, WidgetRef ref) async {
    // Make sure we refresh the inventory
    final view = ref.read(inventoryProvider.notifier);
    await view.refresh();

    return true;
  }

  Future<void> onCleanUpHistory(WidgetRef ref) async {
    final repo = ref.read(repositoryProvider);
    ref.read(editableItemProvider.notifier).cleanUpHistory(repo);
    final view = ref.read(inventoryProvider.notifier);
    await view.refresh();
  }

  Future<void> onHistoryDetailPressed(BuildContext context, WidgetRef ref) async {
    String upc = ref.read(editableItemProvider.notifier).upc;
    await HistoryPage.push(context, upc);
  }

  Future<void> onImagePressed(BuildContext context, WidgetRef ref) async {
    final editableItem = ref.read(editableItemProvider.notifier);
    String upc = editableItem.upc;
    final url = editableItem.imageUrl;

    final result = await UrlInputDialog.show(
      context,
      existingUrl: url,
      customButton: const Text('Find Image'),
      customButtonAction: () async {
        // Allow the user to browse to a URL
        return ImageBrowserPage.push(context, upc);
      },
    );

    // If the user entered a URL, download and cache the image
    // as long as it isn't the same as the previous one
    if (result != null && result != editableItem.imageUrl) {
      editableItem.imageUrl = result;

      // Ensure we have a valid UPC
      if (editableItem.upc.isEmpty) {
        Log.w('ItemDetailPage: Cannot add image from URL $result because UPC is empty.');
        return;
      }

      final imageCache = ref.read(itemThumbnailCache.notifier);
      await imageCache.downloadImage(result, editableItem.upc, replace: true);
    }
  }

  Future<void> onSaveButtonPressed(BuildContext context, WidgetRef ref) async {
    final editableItem = ref.read(editableItemProvider.notifier);
    final repo = ref.read(repositoryProvider);
    editableItem.save(repo);

    final view = ref.read(inventoryProvider.notifier);
    await view.refresh();

    final shoppingList = ref.read(shoppingListProvider.notifier);
    await shoppingList.refreshAll();

    if (context.mounted) {
      // Return a JoinedItem to the previous page
      final state = ref.read(editableItemProvider);
      final item = JoinedItem(state.item, state.inventory);
      Navigator.pop(context, item);
    }
  }

  static Future<JoinedItem?> push(
    BuildContext context,
    WidgetRef ref,
    Item item,
    Inventory inventory,
  ) async {
    final identifiers = ref.read(repositoryProvider).identifiers.getMapForUpc(item.upc);
    final itemProv = ref.read(editableItemProvider.notifier);
    itemProv.init(item, inventory, identifiers);

    return await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ItemDetailPage(item)),
    );
  }
}
