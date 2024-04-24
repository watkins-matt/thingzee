import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:receipt_ocr/post_scan_handler.dart';
import 'package:receipt_ocr/state/camera_state.dart';
import 'package:receipt_ocr/text_merge_strategy.dart';
import 'package:receipt_parser/model/receipt.dart';
import 'package:receipt_parser/stores/target.dart';

class LiveReceiptScannerPage extends ConsumerWidget {
  final PostScanHandler postScanHandler;
  const LiveReceiptScannerPage({super.key, required this.postScanHandler});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    final cameraControllerAsyncValue = ref.watch(cameraControllerProvider);
    final cameraAsyncValue = ref.watch(cameraProvider);

    return cameraControllerAsyncValue.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Receipt Scanner')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Receipt Scanner')),
        body: Center(child: Text('Error: ${err.toString()}')),
      ),
      data: (controller) {
        return cameraAsyncValue.when(
          loading: () => Scaffold(
            appBar: AppBar(title: const Text('Receipt Scanner')),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Scaffold(
            appBar: AppBar(title: const Text('Receipt Scanner')),
            body: Center(child: Text('Error: ${err.toString()}')),
          ),
          data: (camera) {
            return Scaffold(
              appBar: AppBar(title: const Text('Receipt Scanner')),
              body: LiveTextScanner(
                camera: camera,
                controller: controller,
                postScanHandler: postScanHandler,
                textRecognizer: ref.read(textRecognizerProvider),
              ),
            );
          },
        );
      },
    );
  }
}

class LiveTextScanner extends ConsumerStatefulWidget {
  final CameraController controller;
  final PostScanHandler postScanHandler;
  final TextRecognizer textRecognizer;
  final CameraDescription camera;

  const LiveTextScanner({
    super.key,
    required this.camera,
    required this.controller,
    required this.postScanHandler,
    required this.textRecognizer,
  });

  @override
  ConsumerState<LiveTextScanner> createState() => _LiveTextScannerState();
}

class _LiveTextScannerState extends ConsumerState<LiveTextScanner> with WidgetsBindingObserver {
  bool _isProcessing = false;
  TargetReceiptParser parser = TargetReceiptParser();
  ParsedReceipt currentReceipt = ParsedReceipt(items: const [], date: DateTime.now());
  DateTime _lastProcessedTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CameraPreview(widget.controller),
        Positioned(
          bottom: 20,
          right: 20,
          child: ValueListenableBuilder<ParsedReceipt>(
            valueListenable: ValueNotifier(currentReceipt),
            builder: (context, receipt, child) {
              return ElevatedButton(
                onPressed: () {
                  widget.postScanHandler.handleScannedText(context, ref, parser.rawText);
                },
                child: Text(
                  'Items: ${receipt.items.length}, Total: \$${receipt.calculatedSubtotal.toStringAsFixed(2)}',
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController cameraController = widget.controller;

    if (!cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      cameraController.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera controller if needed
      if (!cameraController.value.isStreamingImages) {
        cameraController.startImageStream(_processCameraImage);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.stopImageStream();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.startImageStream(_processCameraImage);
  }

  Future<void> processImage(InputImage inputImage) async {
    final recognizedText = await widget.textRecognizer.processImage(inputImage);
    final size = inputImage.metadata?.size;

    final text = await _recognizeAndMergeText(recognizedText, size ?? const Size(720, 1280));
    parser.parse(text);

    if (!mounted) return;
    setState(() {
      currentReceipt = parser.receipt;
    });
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final orientations = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };

    final camera = widget.camera;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = orientations[widget.controller.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _processCameraImage(CameraImage image) async {
    final currentTime = DateTime.now();
    if (_isProcessing ||
        currentTime.difference(_lastProcessedTime) < const Duration(milliseconds: 500)) {
      // Skip the frame if we are already processing an image or if it's too soon since the last processed frame
      return;
    }

    _isProcessing = true;
    _lastProcessedTime = currentTime;

    try {
      final InputImage? inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        Log.e('Failed to convert image from camera image...');
        return;
      }

      await processImage(inputImage);
    } catch (e) {
      Log.e('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<String> _recognizeAndMergeText(RecognizedText recognizedText, Size size) async {
    final lines = RecognizedTextMergeStrategy.processTextRecognitionResult(recognizedText, size);
    return lines.join('\n');
  }
}
