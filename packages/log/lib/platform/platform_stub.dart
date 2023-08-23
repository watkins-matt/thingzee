import 'dart:io';

const bool platformKIsWeb = false;

Future<String?> getPlatformLogDirectoryPath() async {
  return Directory.current.path;
}

void platformPrint(String message) {
  print(message);
}
