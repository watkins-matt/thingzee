import 'platform_stub.dart'
    if (dart.library.js) 'platform_web.dart'
    if (dart.library.ui) 'platform_flutter.dart';

const bool kIsWeb = platformKIsWeb;

Future<String?> getLogDirectoryPath() => getPlatformLogDirectoryPath();
void platformDebugPrint(String message) => platformPrint(message);
