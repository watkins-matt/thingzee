import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/preferences.dart';
import 'package:thingzee/extension/enum.dart';
import 'package:thingzee/main.dart';
import 'package:thingzee/pages/settings/state/preference_keys.dart';

final isDarkModeProvider = Provider.family<bool, BuildContext>((ref, context) {
  final themeMode = ref.watch(themeModeProvider);

  switch (themeMode) {
    case AppTheme.dark:
      return true;
    case AppTheme.light:
      return false;
    case AppTheme.system:
      final brightnessValue = MediaQuery.of(context).platformBrightness;
      return brightnessValue == Brightness.dark;
  }
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final repo = ref.watch(repositoryProvider);
  return SettingsNotifier(repo.prefs, repo.securePrefs);
});

final themeModeProvider = Provider<AppTheme>((ref) {
  final appThemeString =
      ref.watch(settingsProvider.select((s) => s.settings[PreferenceKey.appTheme]));
  int? appTheme = int.tryParse(appThemeString ?? '');

  return enumFromIndex(AppTheme.values, appTheme, PreferenceKeyDefault.appTheme);
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Preferences _prefs;
  final Preferences _securePrefs;
  final Set<String> _monitored = {PreferenceKey.mealieURL};
  final Set<String> _monitoredSecure = {SecurePreferenceKey.mealieApiKey};
  final Set<String> _monitoredInt = {PreferenceKey.restockDayCount, PreferenceKey.appTheme};

  SettingsNotifier(this._prefs, this._securePrefs) : super(SettingsState()) {
    for (final key in _monitored) {
      getString(key);
    }

    for (final key in _monitoredSecure) {
      secureGetString(key);
    }

    for (final key in _monitoredInt) {
      getInt(key);
    }
  }

  int? getInt(String key) {
    final value = _prefs.getInt(key);
    if (value != null && value.toString() != state.settings[key]) {
      state = state.copyWith(settings: Map.from(state.settings)..[key] = value.toString());
    }
    return value;
  }

  String? getString(String key) {
    final value = _prefs.getString(key);
    if (value != null && value != state.settings[key]) {
      state = state.copyWith(settings: Map.from(state.settings)..[key] = value);
    }
    return value;
  }

  String? secureGetString(String key) {
    final value = _securePrefs.getString(key);
    if (value != null && value != state.secureSettings[key]) {
      state = state.copyWith(secureSettings: Map.from(state.secureSettings)..[key] = value);
    }
    return value;
  }

  Future<void> secureSetString(String key, String value) async {
    await _securePrefs.setString(key, value);
    state = state.copyWith(secureSettings: Map.from(state.secureSettings)..[key] = value);
  }

  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
    state = state.copyWith(settings: Map.from(state.settings)..[key] = value.toString());
  }

  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
    state = state.copyWith(settings: Map.from(state.settings)..[key] = value);
  }
}

class SettingsState {
  final Map<String, String> settings;
  final Map<String, String> secureSettings;

  SettingsState({
    this.settings = const {},
    this.secureSettings = const {},
  });

  SettingsState copyWith({
    Map<String, String>? settings,
    Map<String, String>? secureSettings,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      secureSettings: secureSettings ?? this.secureSettings,
    );
  }
}
