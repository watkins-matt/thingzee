import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:thingzee/app.dart';
import 'package:thingzee/data/csv_export_service.dart';
import 'package:thingzee/data/csv_import_service.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';
import 'package:thingzee/pages/log/log_viewer_page.dart';
import 'package:thingzee/pages/settings/state/preference_keys.dart';
import 'package:thingzee/pages/settings/state/settings_state.dart';
import 'package:thingzee/pages/settings/widget/text_entry_dialog.dart';

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

  static Future<void> push(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final mealieUrlText =
        ref.watch(settingsProvider.select((s) => s.settings[PreferenceKey.mealieURL]));
    final mealieApiKeyText = ref
        .watch(settingsProvider.select((s) => s.secureSettings[SecurePreferenceKey.mealieApiKey]));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SettingsList(
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
          lightTheme: SettingsThemeData(settingsListBackground: Theme.of(context).canvasColor),
          sections: [
            SettingsSection(
              title: const Text('Backup & Restore'),
              tiles: [
                SettingsTile(
                    title: const Text('Export Backup (Zipped CSV Archive)'),
                    onPressed: onExportButtonPressed),
                SettingsTile(
                    title: const Text('Import Backup (Zipped CSV Archive)'),
                    onPressed: onImportButtonPressed),
              ],
            ),
            SettingsSection(
              title: const Text('Integrations'),
              tiles: [
                SettingsTile(
                  title: const Text('Mealie URL'),
                  value: mealieUrlText != null ? Text(mealieUrlText) : const Text('Not Set'),
                  onPressed: onMealieUrlButtonPreseed,
                ),
                SettingsTile(
                    title: const Text('Mealie API Key'),
                    value: mealieApiKeyText != null ? const Text('Hidden') : const Text('Not Set'),
                    onPressed: onMealieApiKeyButtonPreseed),
              ],
            ),
            SettingsSection(
              title: const Text('Debug'),
              tiles: [
                SettingsTile(
                  title: const Text('Log Viewer'),
                  onPressed: onLogViewerButtonPressed,
                )
              ],
            ),
          ]),
    );
  }

  Future<void> onExportButtonPressed(BuildContext context) async {
    await CsvExportService().exportAllData(App.repo);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Data exported successfully.'),
    ));
  }

  Future<void> onImportButtonPressed(BuildContext context) async {
    await CsvImportService().importAllData(App.repo);

    if (!mounted) return;
    await _refreshPostImport(context);
  }

  Future<void> onLogViewerButtonPressed(context) async {
    await LogViewerPage.push(context);
  }

  Future<void> onMealieApiKeyButtonPreseed(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => TextEntryDialog(
        title: 'Enter Mealie API Key',
        controller: controller,
      ),
    );
    if (result != null) {
      await ref
          .read(settingsProvider.notifier)
          .secureSetString(SecurePreferenceKey.mealieApiKey, result);
    }
  }

  Future<void> onMealieUrlButtonPreseed(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => TextEntryDialog(
        title: 'Enter Mealie URL',
        controller: controller,
      ),
    );
    if (result != null) {
      await ref.read(settingsProvider.notifier).setString(PreferenceKey.mealieURL, result);
    }
  }

  Future<String?> pickFilePath() async {
    FilePickerResult? filePickerResult = await FilePicker.platform.pickFiles();
    return filePickerResult?.files.single.path;
  }

  Future<void> _refreshPostImport(BuildContext context) async {
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
