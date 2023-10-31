enum AppTheme {
  dark,
  light,
  system,
}

class PreferenceKey {
  static const String mealieURL = 'mealieURL';
  static const String restockDayCount = 'restockDayCount';
  static const String appTheme = 'appTheme';
}

class PreferenceKeyDefault {
  static const String restockDayCount = '12';
  static const AppTheme appTheme = AppTheme.system;
}

class SecurePreferenceKey {
  static const String mealieApiKey = 'mealieApiKey';
}
