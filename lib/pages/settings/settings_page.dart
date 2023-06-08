import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quiver/core.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:thingzee/app.dart';
import 'package:thingzee/data/csv_exporter.dart';
import 'package:thingzee/data/csv_importer.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';

// Settings page
// Features to include:
// - Regenerate random scan audit
// - Location editor
// - View all unassigned (unlocated) items
// - Debug functionality to reset db

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  Future<Optional<String>> pickFilePath() async {
    FilePickerResult? filePickerResult = await FilePicker.platform.pickFiles();
    Optional<String> chosenPath = const Optional.absent();

    if (filePickerResult != null) {
      chosenPath = Optional.fromNullable(filePickerResult.files.single.path);
    }

    return chosenPath;
  }

  Future<void> onImportHistory(BuildContext context) async {
    final filePath = await pickFilePath();

    if (filePath.isPresent) {
      final file = File(filePath.value);
      final contents = await file.readAsString();

      await CSVImporter.importHistory(contents, App.repo);

      final view = ref.read(inventoryProvider.notifier);
      await view.refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Backup imported.'),
      ));
    }
  }

  Future<void> onImportProductData(BuildContext context) async {
    final filePath = await pickFilePath();

    if (filePath.isPresent) {
      final file = File(filePath.value);
      final contents = await file.readAsString();

      await CSVImporter.importProductData(contents, App.repo);

      final view = ref.read(inventoryProvider.notifier);
      await view.refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Backup imported.'),
      ));
    }
  }

  Future<void> onImportInventoryData(BuildContext context) async {
    final filePath = await pickFilePath();

    if (filePath.isPresent) {
      final file = File(filePath.value);
      final contents = await file.readAsString();

      await CSVImporter.importInventoryData(contents, App.repo);

      final view = ref.read(inventoryProvider.notifier);
      final imageCache = ref.read(itemThumbnailCache.notifier);

      await view.refresh();
      await view.downloadImages(imageCache);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Backup imported.'),
      ));
    }
  }

  Future<void> onExportInfoBackupPressed(BuildContext context) async {
    // Generate CSV data
    String csvData = await CSVExporter.exportProductData(App.repo);

    // Get application directory
    Directory appDocDir = await getApplicationDocumentsDirectory();

    // Create export directory if it doesn't exist
    String exportDir = '${appDocDir.path}/export/';
    Directory(exportDir).createSync(recursive: true);
    final dateTime = DateTime.now().toIso8601String().replaceAll('.', '-').replaceAll(':', '-');

    // Write CSV data to a file
    String filePath = '${appDocDir.path}/info_backup_$dateTime.csv';
    File file = File(filePath);
    await file.writeAsString(csvData);

    // Share the file
    await Share.shareXFiles([XFile(filePath)], text: 'Backup Info');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Backup written to downloads folder.'),
    ));
  }

  Future<void> onExportInventoryBackupPressed(BuildContext context) async {
    // Generate CSV data
    String csvData = await CSVExporter.exportInventoryData(App.repo);

    // Get application directory
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String exportDir = '${appDocDir.path}/export/';

    // Create export directory if it doesn't exist
    Directory(exportDir).createSync(recursive: true);
    final dateTime = DateTime.now().toIso8601String().replaceAll('.', '-').replaceAll(':', '-');

    String filePath = '${appDocDir.path}/inventory_backup_$dateTime.csv';

    // Write CSV data to a file
    File file = File(filePath);
    await file.writeAsString(csvData);

    // Share the file
    await Share.shareXFiles([XFile(filePath)], text: 'Backup Inventory');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Backup written to downloads folder.'),
    ));
  }

  Future<void> onExportHistoryButtonPressed(BuildContext context) async {
    // Generate CSV data
    String csvData = await CSVExporter.exportHistory(App.repo);

    // Get application directory
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String exportDir = '${appDocDir.path}/export/';

    // Create export directory if it doesn't exist
    Directory(exportDir).createSync(recursive: true);
    final dateTime = DateTime.now().toIso8601String().replaceAll('.', '-').replaceAll(':', '-');

    String filePath = '${appDocDir.path}/history_backup_$dateTime.csv';

    // Write CSV data to a file
    File file = File(filePath);
    await file.writeAsString(csvData);

    // Share the file
    await Share.shareXFiles([XFile(filePath)], text: 'Backup History');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('History backup exported.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SettingsList(
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
          lightTheme: SettingsThemeData(settingsListBackground: Theme.of(context).canvasColor),
          sections: [
            SettingsSection(
              title: const Text('Backup'),
              tiles: [
                SettingsTile(
                    title: const Text('Export History Backup (CSV)'),
                    onPressed: onExportHistoryButtonPressed),
                SettingsTile(
                    title: const Text('Export Info Backup (CSV)'),
                    onPressed: onExportInfoBackupPressed),
                SettingsTile(
                    title: const Text('Export Inventory Backup (CSV)'),
                    onPressed: onExportInventoryBackupPressed),
              ],
            ),
            SettingsSection(
              title: const Text('Restore'),
              tiles: [
                SettingsTile(
                    title: const Text('Import History Info Backup (CSV)'),
                    onPressed: onImportHistory),
                SettingsTile(
                    title: const Text('Import Product Info Backup (CSV)'),
                    onPressed: onImportProductData),
                SettingsTile(
                  title: const Text('Import Inventory Backup (CSV)'),
                  onPressed: onImportInventoryData,
                ),
              ],
            ),
          ]),
    );
  }
}
