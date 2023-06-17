import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:quiver/core.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/data/history_csv_importer.dart';
import 'package:thingzee/data/inventory_csv_importer.dart';
import 'package:thingzee/data/item_csv_importer.dart';

class CsvImportService {
  static const String _importDirName = 'import';

  Future<void> importAllData(Repository repo) async {
    final importMethods = {
      'history.csv': HistoryCsvImporter().import,
      'item.csv': ItemCsvImporter().import,
      'inventory.csv': InventoryCsvImporter().import,
    };

    Optional<String> chosenFilePath = await pickFilePath();

    if (chosenFilePath.isPresent) {
      String zipFilePath = chosenFilePath.value;
      List<String> csvFiles = await _extractFilesFromZip(zipFilePath);

      // Try to import each csv file mentioned in importMethods
      for (final entry in importMethods.entries) {
        // Search for a file in csvFiles whose name matches
        String filePath = csvFiles.firstWhere((element) => path.basename(element) == entry.key,
            orElse: () => ''); // If no match found, return an empty string

        // There was a matching file, so import it
        if (filePath.isNotEmpty) {
          String contents = await File(filePath).readAsString();
          // Import the data from the csv file using the defined import method
          await entry.value(contents, repo);
        }
      }
    }
  }

  Future<Optional<String>> pickFilePath() async {
    FilePickerResult? filePickerResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    Optional<String> chosenPath = const Optional.absent();

    if (filePickerResult != null) {
      String filePath = filePickerResult.files.single.path!;
      if (filePath.endsWith('.zip')) {
        chosenPath = Optional.of(filePath);
      }
    }

    return chosenPath;
  }

  Future<List<String>> _extractFilesFromZip(String zipFilePath) async {
    List<String> csvFiles = [];
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String importDirPath = path.join(appDocDir.path, _importDirName);

    // Create the import dir if it doesn't exist
    Directory(importDirPath).createSync(recursive: true);

    final bytes = File(zipFilePath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Extract all the files
    for (final file in archive) {
      if (file.isFile) {
        final data = file.content as List<int>;
        File(path.join(importDirPath, file.name))
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
        csvFiles.add(path.join(importDirPath, file.name));
      }
    }

    return csvFiles;
  }
}
