import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/preferences_service.dart';

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});

final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return DarkModeNotifier(prefs);
});

final onboardingDoneProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return prefs.isOnboardingDone;
});

final notificationsEnabledProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return prefs.notificationsEnabled;
});

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return LocaleNotifier(prefs);
});

class DarkModeNotifier extends StateNotifier<bool> {
  final PreferencesService _prefs;

  DarkModeNotifier(this._prefs) : super(_prefs.isDarkMode);

  Future<void> toggle() async {
    state = !state;
    await _prefs.setDarkMode(state);
  }

  Future<void> setDarkMode(bool value) async {
    state = value;
    await _prefs.setDarkMode(value);
  }
}

class LocaleNotifier extends StateNotifier<Locale> {
  final PreferencesService _prefs;

  LocaleNotifier(this._prefs) : super(Locale(_prefs.language));

  Future<void> setLocale(String lang) async {
    state = Locale(lang);
    await _prefs.setLanguage(lang);
  }
}
