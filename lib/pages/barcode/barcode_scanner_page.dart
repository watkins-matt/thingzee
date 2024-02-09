import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:qr_mobile_vision/qr_camera.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:thingzee/main.dart';
import 'package:thingzee/pages/detail/item_detail_page.dart';
import 'package:thingzee/pages/detail/state/editable_item.dart';

String upceToA(String upce) {
  String manufacturer = upce.substring(1, 7);
  String productCode = '';
  if (manufacturer[5] == '0' || manufacturer[5] == '1' || manufacturer[5] == '2') {
    productCode =
        '${manufacturer[0]}${manufacturer[1]}${manufacturer[5]}0000${manufacturer[2]}${manufacturer[3]}${manufacturer[4]}';
  } else if (manufacturer[5] == '3') {
    productCode =
        '${manufacturer[0]}${manufacturer[1]}${manufacturer[2]}00000${manufacturer[3]}${manufacturer[4]}';
  } else if (manufacturer[5] == '4') {
    productCode =
        '${manufacturer[0]}${manufacturer[1]}${manufacturer[2]}${manufacturer[3]}00000${manufacturer[4]}';
  } else {
    productCode =
        '${manufacturer[0]}${manufacturer[1]}${manufacturer[2]}${manufacturer[3]}${manufacturer[4]}0000${manufacturer[5]}';
  }
  return '0$productCode';
}

enum BarcodeScannerMode { showItemDetail, addToShoppingList }

class BarcodeScannerPage extends ConsumerStatefulWidget {
  final BarcodeScannerMode mode;
  final String location;

  const BarcodeScannerPage(this.mode, {super.key, this.location = ''});

  @override
  ConsumerState<BarcodeScannerPage> createState() => _BarcodeScannerPageState();

  static Future<void> push(BuildContext context, BarcodeScannerMode mode) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BarcodeScannerPage(mode)),
    );
  }
}

class _BarcodeScannerPageState extends ConsumerState<BarcodeScannerPage> {
  bool finishedScanning = false;
  String upc = '';
  String ean = '';
  Timer? timer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: QrCamera(
            qrCodeCallback: (barcode) {
              if (!finishedScanning) {
                onBarcodeScanned(context, barcode);
              }
            },
            notStartedBuilder: (context) => Container(
              color: Colors.black,
            ),
          ),
        ));
  }

  Future<void> loadItemDetail(BuildContext context, String barcode) async {
    final repo = ref.read(repositoryProvider);
    final defaultItem = Item(
      upc: barcode,
      name: 'Unknown Item',
      category: 'Food & Beverage',
    );

    // First try to find the product in the product db
    Item item = repo.items.get(barcode) ?? defaultItem;

    final defaultInventory = Inventory(
      upc: barcode,
      amount: 1,
      updated: DateTime.now(),
    );

    final inv = repo.inv.get(barcode) ?? defaultInventory;
    final itemProv = ref.watch(editableItemProvider.notifier);

    itemProv.init(item, inv); // These are guaranteed to be valid (initialized above)
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ItemDetailPage(item)),
    );
  }

  Future<void> onBarcodeScanned(BuildContext context, String? barcode) async {
    if (barcode != null &&
        (barcode.length == 12 ||
            barcode.length == 13 ||
            barcode.length == 7 ||
            barcode.length == 8)) {
      if (barcode.length == 7) {
        barcode = upceToA(barcode);
      }

      if (barcode.length == 12 && upc.isEmpty) {
        upc = barcode;
        Log.i('Found UPC: $upc');
      } else if (barcode.length == 13 || barcode.length == 8 && ean.isEmpty) {
        ean = barcode;
        Log.i('Found EAN: $ean');
      }

      if (timer == null || !timer!.isActive) {
        timer = Timer(const Duration(milliseconds: 50), () async {
          if (!finishedScanning) {
            finishedScanning = true;
            await loadItemDetail(context, upc.isEmpty ? ean : upc);
          }
        });
      }
    }
  }
}
