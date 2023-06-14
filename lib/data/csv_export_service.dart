import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:repository/repository.dart';
import 'package:share_plus/share_plus.dart';
import 'package:thingzee/data/csv_exporter.dart';

class CsvExportService {
  // The temporary directory to store the exported files
  static const String _exportDirName = 'export';

  // Exports all of the data, zips it and shares the file
  Future<void> exportAllData(Repository repo) async {
    final exportMethods = {
      'history.csv': CSVExporter.exportHistory,
      'item.csv': CSVExporter.exportProductData,
      'inventory.csv': CSVExporter.exportInventoryData,
    };

    for (final entry in exportMethods.entries) {
      String csvData = await entry.value(repo);
      String fileName = entry.key;
      await _writeToFile(csvData, fileName);
    }

    String zipPath = await _createBackupZip();
    await _shareFile(zipPath);
  }

  Future<String> _writeToFile(String csvData, String fileName) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String dirPath = path.join(appDocDir.path, _exportDirName);

    // Create potentially missing directory, or do nothing if it exists
    _createDirectory(dirPath);
    String filePath = path.join(dirPath, fileName);
    File file = File(filePath);
    await file.writeAsString(csvData);

    return filePath;
  }

  void _createDirectory(String path) {
    Directory(path).createSync(recursive: true);
  }

  Future<String> _createBackupZip() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String dirPath = path.join(appDocDir.path, _exportDirName);

    final encoder = ZipFileEncoder();
    final dateTime = DateTime.now().toIso8601String().replaceAll('.', '-').replaceAll(':', '-');

    String zipFilePath = path.join(dirPath, 'backup_$dateTime.zip');
    encoder.create(zipFilePath);

    // Add all files in the export directory to the zip file
    Directory(dirPath)
        .listSync()
        .where((element) => element.path.endsWith('.csv'))
        .forEach((element) {
      encoder.addFile(File(element.path));
    });

    encoder.close();
    return zipFilePath;
  }

  Future<void> _shareFile(String path) async {
    await Share.shareXFiles([XFile(path)], text: 'Backup Data');
  }
}
