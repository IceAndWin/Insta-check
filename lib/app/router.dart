import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/localization/strings.dart';
import '../features/analysis/presentation/screens/search_screen.dart';
import '../features/analysis/presentation/screens/follow_analysis_screen.dart';
import '../features/analysis/presentation/screens/history_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/providers/settings_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: GlobalKey<NavigatorState>(),
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HistoryScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/follow-analysis/:username',
            builder: (_, state) => FollowAnalysisScreen(
              username: state.pathParameters['username']!,
            ),
          ),
        ],
      ),
    ],
  );
});

class _AppShell extends ConsumerWidget {
  final Widget child;

  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;
    String t(String key) => Strings.tr(key, lang: lang);
    final location = GoRouterState.of(context).uri.toString();
    final isDetail = location.startsWith('/follow-analysis/');

    int currentIndex(String loc) {
      if (loc == '/dashboard') return 1;
      if (loc == '/settings') return 2;
      return 0;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: isDetail
          ? null
          : BottomNavigationBar(
              currentIndex: currentIndex(location),
              onTap: (i) {
                switch (i) {
                  case 0: context.go('/');
                  case 1: context.go('/dashboard');
                  case 2: context.go('/settings');
                }
              },
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.search_rounded),
                  label: t('nav.analyze'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.history_rounded),
                  label: t('nav.history'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.settings_outlined),
                  activeIcon: const Icon(Icons.settings_rounded),
                  label: t('nav.settings'),
                ),
              ],
            ),
    );
  }
}
