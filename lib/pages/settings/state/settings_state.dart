import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/preferences.dart';
import 'package:repository/database/preferences_secure.dart';
import 'package:thingzee/app.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(App.repo.prefs, App.repo.securePrefs);
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Preferences _prefs;
  final SecurePreferences _securePrefs;

  SettingsNotifier(this._prefs, this._securePrefs) : super(SettingsState());

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
