import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:qr_mobile_vision/qr_camera.dart';

class QuickBarcodeScanner extends HookWidget {
  const QuickBarcodeScanner({super.key});

  @override
  Widget build(BuildContext context) {
    final finishedScanning = useState(false);
    final barcode = useState<String>('');

    void handleBarcodeScanned(String scannedBarcode) {
      if (!finishedScanning.value && scannedBarcode.isNotEmpty) {
        finishedScanning.value = true;
        barcode.value = scannedBarcode;
        Navigator.pop(context, barcode.value);
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: QrCamera(
          qrCodeCallback: (code) {
            if (code != null) {
              handleBarcodeScanned(code);
            }
          },
          notStartedBuilder: (context) => Container(color: Colors.black),
        ),
      ),
    );
  }

  static Future<String?> scanBarcode(BuildContext context) async {
    return Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QuickBarcodeScanner()),
    );
  }
}
