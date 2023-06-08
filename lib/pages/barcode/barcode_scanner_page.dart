import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_mobile_vision/qr_camera.dart';
import 'package:quiver/core.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:thingzee/app.dart';
import 'package:thingzee/pages/detail/item_detail_page.dart';
import 'package:thingzee/pages/detail/state/editable_item.dart';

enum BarcodeScannerMode { showItemDetail, addToShoppingList }

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

class BarcodeScannerPage extends ConsumerStatefulWidget {
  final BarcodeScannerMode mode;
  final String location;

  const BarcodeScannerPage(this.mode, {Key? key, this.location = ''}) : super(key: key);

  @override
  ConsumerState<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
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
        App.log.d('Scanned UPC: $upc');
      } else if (barcode.length == 13 || barcode.length == 8 && ean.isEmpty) {
        ean = barcode;
        App.log.d('Scanned EAN: $ean');
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

  Future<void> loadItemDetail(BuildContext context, String barcode) async {
    // First try to find the product in the product db
    var item = App.repo.items.get(barcode);

    // No product found
    if (item.isNotPresent) {
      item = Optional.of(Item());
      item.value.upc = barcode;
      item.value.name = 'Unknown Item';
      item.value.category = 'Food & Beverage';
    }

    var inv = App.repo.inv.get(barcode);

    if (inv.isNotPresent) {
      // If there is no inventory present, assume we are adding the
      // first one so the amount will be one
      inv = Optional.of(Inventory());
      inv.value.upc = barcode;
      inv.value.amount = 1;
    }

    final history = App.repo.hist.get(barcode);

    final itemProv = ref.watch(editableItemProvider.notifier);
    itemProv.copyFrom(item.value, inv.value, history);
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ItemDetailPage(item.value)),
    );
  }
}
