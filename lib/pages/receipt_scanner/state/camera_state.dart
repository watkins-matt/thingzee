import 'dart:io';

import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/receipt.dart';
import 'package:thingzee/pages/receipt_scanner/parser/parser.dart';

final cameraControllerProvider = FutureProvider.autoDispose<CameraController>((ref) async {
  final cameras = await availableCameras();
  final camera = cameras.first;

  final controller = CameraController(
    camera,
    ResolutionPreset.high,
    enableAudio: false,
    imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
  );

  await controller.initialize();

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});

final cameraProvider = FutureProvider.autoDispose<CameraDescription>((ref) async {
  final cameras = await availableCameras();
  return cameras.first;
});

final receiptParserProvider = StateProvider<ReceiptParser?>((ref) => null);
final receiptProvider = StateProvider<Receipt?>((ref) => null);
final textRecognizerProvider = Provider<TextRecognizer>((ref) => TextRecognizer());
