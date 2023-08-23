import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

const bool platformKIsWeb = bool.fromEnvironment('dart.library.js_util');

Future<String?> getPlatformLogDirectoryPath() async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

void platformPrint(String message) {
  debugPrint(message);
}
