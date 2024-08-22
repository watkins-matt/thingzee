const bool platformKIsWeb = true;

// Writing files is not supported on the web.
Future<String?> getPlatformLogDirectoryPath() async {
  return null;
}

void platformPrint(String message) {
  // ignore: avoid_print
  print(message);
}
