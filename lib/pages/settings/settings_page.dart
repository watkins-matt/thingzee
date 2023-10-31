import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:thingzee/data/csv_export_service.dart';
import 'package:thingzee/data/csv_import_service.dart';
import 'package:thingzee/extension/string.dart';
import 'package:thingzee/main.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';
import 'package:thingzee/pages/log/log_viewer_page.dart';
import 'package:thingzee/pages/settings/state/preference_keys.dart';
import 'package:thingzee/pages/settings/state/settings_state.dart';
import 'package:thingzee/pages/settings/widget/text_entry_dialog.dart';
import 'package:thingzee/pages/settings/widget/theme_picker_dialog.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';

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
    final themeMode = ref.watch(themeModeProvider);
    final mealieUrlText =
        ref.watch(settingsProvider.select((s) => s.settings[PreferenceKey.mealieURL]));
    final mealieApiKeyText = ref
        .watch(settingsProvider.select((s) => s.secureSettings[SecurePreferenceKey.mealieApiKey]));
    final restockDayCount =
        ref.watch(settingsProvider.select((s) => s.settings[PreferenceKey.restockDayCount])) ??
            PreferenceKeyDefault.restockDayCount;

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
              title: const Text('Shopping List'),
              tiles: [
                SettingsTile(
                    title: const Text('Restock Items Running Out Within (Days)'),
                    description: const Text(
                        'Set the number of days to look ahead for items running out.'
                        'For example, if set to 7, items running out within the next 7 days will be added to the shopping list.'),
                    onPressed: onRestockDayCountPressed,
                    value: Text(restockDayCount)),
              ],
            ),
            SettingsSection(
              title: const Text('Theme'),
              tiles: [
                SettingsTile(
                  title: const Text('App Theme'),
                  value: Text(themeMode.toString().split('.').last.titleCase),
                  onPressed: (BuildContext context) => onThemeButtonPressed(context),
                ),
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
    final repo = ref.watch(repositoryProvider);
    await CsvExportService().exportAllData(repo);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Data exported successfully.'),
    ));
  }

  Future<void> onImportButtonPressed(BuildContext context) async {
    final repo = ref.watch(repositoryProvider);
    await CsvImportService().importAllData(repo);

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

  Future<void> onRestockDayCountPressed(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => TextEntryDialog(
        title: 'Enter Restock Day Count',
        controller: controller,
        validator: (value) {
          return (value != null && int.tryParse(value) != null)
              ? null
              : 'Please enter a valid integer';
        },
      ),
    );

    if (result != null && int.tryParse(result) != null) {
      await ref
          .read(settingsProvider.notifier)
          .setInt(PreferenceKey.restockDayCount, int.parse(result));

      // Update the shopping list
      ref.read(shoppingListProvider.notifier).refresh();
    }
  }

  Future<void> onThemeButtonPressed(BuildContext context) async {
    final currentTheme = ref.read(themeModeProvider);
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return ThemePickerDialog(
          initialTheme: currentTheme,
          onThemeSelected: (selectedTheme) async {
            // Update the theme if different
            if (selectedTheme != currentTheme) {
              await ref
                  .read(settingsProvider.notifier)
                  .setInt(PreferenceKey.appTheme, selectedTheme.index);
            }
          },
        );
      },
    );
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
