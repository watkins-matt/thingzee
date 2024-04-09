import 'package:flutter/material.dart';
import 'package:thingzee/pages/settings/state/preference_keys.dart';
import 'package:util/extension/string.dart';

typedef OnThemeSelected = void Function(AppTheme selectedTheme);

class ThemePickerDialog extends StatelessWidget {
  final AppTheme initialTheme;
  final OnThemeSelected onThemeSelected;

  const ThemePickerDialog({super.key, required this.initialTheme, required this.onThemeSelected});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Select Theme'),
      children: AppTheme.values.map((mode) {
        return SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context);
            onThemeSelected(mode);
          },
          child: Text(mode.toString().split('.').last.titleCase),
        );
      }).toList(),
    );
  }
}
