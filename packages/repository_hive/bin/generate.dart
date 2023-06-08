import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

const source = '../../repository/lib/model';
const dest = '../lib/model';

void main() async {
  var scriptUri = Platform.script;
  var scriptDir = scriptUri.resolve('.');

  var srcUri = scriptDir.resolve(source);
  var destUri = scriptDir.resolve(dest);

  var srcDir = Directory.fromUri(srcUri);
  var destDir = Directory.fromUri(destUri);

  // Ensure the destination directory exists
  if (!destDir.existsSync()) {
    await destDir.create(recursive: true);
  }

  // Copy files from source to destination and keep track of the copied files
  var copiedFiles = <File>[];
  await for (final entity in srcDir.list(recursive: false, followLinks: false)) {
    if (entity is File) {
      var newFile = await entity.copy(path.join(destDir.path, path.basename(entity.path)));
      copiedFiles.add(newFile);
    }
  }

  String workingDir = Directory.fromUri(scriptUri.resolve('..')).path;

  // Run "dart run build_runner build"
  var process = await Process.start(
      'dart', ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      workingDirectory: workingDir);

  // Print output in real-time
  process.stdout.transform(utf8.decoder).listen((data) {
    stdout.write(data);
  });

  process.stderr.transform(utf8.decoder).listen((data) {
    stderr.write(data);
  });

  await process.exitCode;

  // Delete copied files
  for (final file in copiedFiles) {
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
