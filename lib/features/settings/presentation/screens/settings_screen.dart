import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../widgets/settings_tile.dart';
import '../providers/settings_provider.dart';
import 'about_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final darkMode = ref.watch(darkModeProvider);
    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;
    String t(String key) => Strings.tr(key, lang: lang);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                t('settings.title'),
                style: AppTypography.h1.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 32),
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.dark_mode_rounded,
                      title: t('settings.dark_mode'),
                      subtitle: t('settings.dark_hint'),
                      iconColor: AppColors.secondary,
                      trailing: Switch.adaptive(
                        value: darkMode,
                        onChanged: (value) {
                          ref.read(darkModeProvider.notifier).setDarkMode(value);
                        },
                        activeColor: AppColors.primary,
                      ),
                    ),
                    const Divider(indent: 56, endIndent: 16),
                    SettingsTile(
                      icon: Icons.language_rounded,
                      title: t('settings.language'),
                      subtitle: lang == 'ru' ? t('settings.lang_ru') : t('settings.lang_en'),
                      iconColor: AppColors.primary,
                      onTap: () => _showLanguagePicker(context, ref, lang),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                    ),
                    const Divider(indent: 56, endIndent: 16),
                    SettingsTile(
                      icon: Icons.notifications_rounded,
                      title: t('settings.notifications'),
                      subtitle: t('settings.notif_hint'),
                      iconColor: AppColors.accent,
                      trailing: Switch.adaptive(
                        value: ref.watch(notificationsEnabledProvider),
                        onChanged: (value) {
                          ref.read(notificationsEnabledProvider.notifier).state = value;
                        },
                        activeColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.storage_rounded,
                      title: t('settings.cache'),
                      subtitle: t('settings.cache_hint'),
                      iconColor: AppColors.accent,
                    ),
                    const Divider(indent: 56, endIndent: 16),
                    SettingsTile(
                      icon: Icons.privacy_tip_rounded,
                      title: t('settings.privacy'),
                      subtitle: t('settings.privacy_hint'),
                      iconColor: AppColors.primary,
                    ),
                    const Divider(indent: 56, endIndent: 16),
                    SettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: t('settings.about'),
                      subtitle: t('settings.about_hint'),
                      iconColor: AppColors.secondary,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AboutScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'InstaCheck v1.0.0',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, String currentLang) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _langOption(ctx, ref, 'en', 'English', currentLang == 'en'),
              _langOption(ctx, ref, 'ru', 'Русский', currentLang == 'ru'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langOption(BuildContext ctx, WidgetRef ref, String code, String label, bool selected) {
    return ListTile(
      title: Text(label),
      trailing: selected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(code);
        Navigator.pop(ctx);
      },
    );
  }
}
