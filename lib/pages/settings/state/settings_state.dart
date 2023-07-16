import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/preferences.dart';
import 'package:thingzee/main.dart';
import 'package:thingzee/pages/settings/state/preference_keys.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final repo = ref.watch(repositoryProvider);
  return SettingsNotifier(repo.prefs, repo.securePrefs);
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Preferences _prefs;
  final Preferences _securePrefs;
  final Set<String> _monitored = {PreferenceKey.mealieURL};
  final Set<String> _monitoredSecure = {SecurePreferenceKey.mealieApiKey};

  SettingsNotifier(this._prefs, this._securePrefs) : super(SettingsState()) {
    for (final key in _monitored) {
      getString(key);
    }

    for (final key in _monitoredSecure) {
      secureGetString(key);
    }
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
