import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  SharedPreferences? _prefs;

  static const _darkModeKey = 'dark_mode';
  static const _languageKey = 'language';
  static const _onboardingDoneKey = 'onboarding_done';
  static const _notificationsKey = 'notifications_enabled';
  static const _lastSyncKey = 'last_sync';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get isDarkMode => _prefs?.getBool(_darkModeKey) ?? false;

  Future<void> setDarkMode(bool value) => _prefs!.setBool(_darkModeKey, value);

  String get language => _prefs?.getString(_languageKey) ?? 'en';

  Future<void> setLanguage(String value) => _prefs!.setString(_languageKey, value);

  bool get isOnboardingDone => _prefs?.getBool(_onboardingDoneKey) ?? false;

  Future<void> setOnboardingDone(bool value) => _prefs!.setBool(_onboardingDoneKey, value);

  bool get notificationsEnabled => _prefs?.getBool(_notificationsKey) ?? true;

  Future<void> setNotificationsEnabled(bool value) => _prefs!.setBool(_notificationsKey, value);

  DateTime? get lastSync {
    final ts = _prefs?.getString(_lastSyncKey);
    return ts != null ? DateTime.tryParse(ts) : null;
  }

  Future<void> setLastSync(DateTime value) => _prefs!.setString(_lastSyncKey, value.toIso8601String());

  Future<bool> clear() => _prefs!.clear();
}
