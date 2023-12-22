import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:thingzee/pages/receipt_scanner/post_scan_handler.dart';
import 'package:thingzee/pages/receipt_scanner/state/camera_state.dart';
import 'package:thingzee/pages/receipt_scanner/text_merge_strategy.dart';

class ReceiptScannerPage extends ConsumerWidget {
  final PostScanHandler postScanHandler;
  const ReceiptScannerPage({super.key, required this.postScanHandler});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(cameraControllerProvider).when(
          loading: () => Scaffold(
            appBar: AppBar(title: const Text('Receipt Scanner')),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Scaffold(
            appBar: AppBar(title: const Text('Receipt Scanner')),
            body: Center(child: Text('Error: ${err.toString()}')),
          ),
          data: (controller) {
            return Scaffold(
              appBar: AppBar(title: const Text('Receipt Scanner')),
              body: Stack(
                children: [
                  CameraPreview(controller),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FloatingActionButton(
                      onPressed: () => _takePicture(context, ref, controller),
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
                ],
              ),
            );
          },
        );
  }

  Future<String> _recognizeAndMergeText(RecognizedText recognizedText, Size size) async {
    final lines = RecognizedTextMergeStrategy.processTextRecognitionResult(recognizedText, size);
    return lines.join('\n');
  }

  Future<String> _recognizeText(WidgetRef ref, XFile? image) async {
    if (image == null) return '';
    final textRecognizer = ref.read(textRecognizerProvider);

    final inputImage = InputImage.fromFilePath(image.path);
    final size = inputImage.metadata?.size;
    final recognizedText = await textRecognizer.processImage(InputImage.fromFilePath(image.path));

    return await _recognizeAndMergeText(recognizedText, size ?? const Size(720, 1280));
  }

  Future<void> _takePicture(
      BuildContext context, WidgetRef ref, CameraController controller) async {
    try {
      if (!context.mounted) return;

      final XFile image = await controller.takePicture();
      final String text = await _recognizeText(ref, image);

      if (context.mounted) {
        postScanHandler.handleScannedText(context, ref, text);
      }
    } catch (e) {
      Log.e(e);
    }
  }
}
