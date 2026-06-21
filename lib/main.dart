import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/storage/preferences_service.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final prefs = PreferencesService();
  await prefs.init();

  if (!prefs.hasLanguagePreference) {
    final deviceLang = WidgetsBinding.instance.platformDispatcher.locale.languageCode.toLowerCase();
    final supportedLang = switch (deviceLang) {
      'ru' => 'ru',
      'en' => 'en',
      _ => 'en',
    };
    await prefs.setLanguage(supportedLang);
  }

  runApp(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(prefs),
      ],
      child: const InstaCheckApp(),
    ),
  );
}
