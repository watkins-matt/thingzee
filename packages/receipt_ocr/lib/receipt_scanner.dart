import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:receipt_ocr/post_scan_handler.dart';
import 'package:receipt_ocr/state/camera_state.dart';
import 'package:receipt_ocr/text_merge_strategy.dart';
import 'package:receipt_parser/generic_parser.dart';
import 'package:receipt_parser/stores/costco.dart';
import 'package:receipt_parser/stores/target.dart';
import 'package:util/extension/string.dart';

enum ParserType { generic, costco, target }

class ReceiptScannerPage extends ConsumerStatefulWidget {
  final PostScanHandler postScanHandler;
  const ReceiptScannerPage({super.key, required this.postScanHandler});

  @override
  ConsumerState<ReceiptScannerPage> createState() => _ReceiptScannerPageState();
}

class _ReceiptScannerPageState extends ConsumerState<ReceiptScannerPage> {
  late ParserType selectedParser;

  @override
  Widget build(BuildContext context) {
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
              appBar: AppBar(
                title: const Text('Receipt Scanner'),
                actions: [
                  _buildParserDropdown(),
                ],
              ),
              body: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(controller),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: FloatingActionButton(
                        onPressed: () => _takePicture(context, ref, controller),
                        child: const Icon(Icons.camera_alt),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
  }

  @override
  void initState() {
    super.initState();

    // Update the selected parser if the default parser is changed
    selectedParser = widget.postScanHandler.parser is GenericReceiptParser
        ? ParserType.generic
        : ParserType.target;
  }

  Widget _buildParserDropdown() {
    return DropdownButton<ParserType>(
      value: selectedParser,
      onChanged: (ParserType? newValue) {
        setState(() {
          selectedParser = newValue!;
          switch (newValue) {
            case ParserType.generic:
              widget.postScanHandler.parser = GenericReceiptParser();
              break;
            case ParserType.costco:
              widget.postScanHandler.parser = CostcoReceiptParser();
              break;
            case ParserType.target:
              widget.postScanHandler.parser = TargetReceiptParser();
              break;
          }
        });
      },
      items: ParserType.values.map((ParserType type) {
        return DropdownMenuItem<ParserType>(
          value: type,
          child: Text(type.toString().split('.').last.titleCase),
        );
      }).toList(),
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
        widget.postScanHandler.handleScannedText(context, ref, text);
      }
    } catch (e) {
      Log.e(e);
    }
  }
}
