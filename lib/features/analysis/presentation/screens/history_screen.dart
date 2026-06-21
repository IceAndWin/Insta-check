import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/strings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../providers/analysis_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _selectionMode = false;
  final Set<String> _selected = {};

  void _toggleSelection(String username) {
    setState(() {
      if (_selected.contains(username)) {
        _selected.remove(username);
        if (_selected.isEmpty) _selectionMode = false;
      } else {
        _selected.add(username);
      }
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selected.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final lang = ref.read(localeProvider).languageCode;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Strings.tr('history.delete_confirm_title', lang: lang)),
        content: Text(Strings.tr('history.delete_selected_confirm', lang: lang)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(Strings.tr('common.cancel', lang: lang))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(Strings.tr('common.delete', lang: lang), style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final repo = ref.read(analysisRepositoryProvider);
    for (final username in _selected) {
      await repo.removeSearchHistory(username);
    }
    ref.invalidate(searchHistoryProvider);
    _exitSelection();
  }

  Future<void> _clearAll() async {
    final lang = ref.read(localeProvider).languageCode;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Strings.tr('history.delete_confirm_title', lang: lang)),
        content: Text(Strings.tr('history.delete_confirm_message', lang: lang)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(Strings.tr('common.cancel', lang: lang))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(Strings.tr('common.delete', lang: lang), style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await ref.read(analysisRepositoryProvider).clearSearchHistory();
    ref.invalidate(searchHistoryProvider);
  }

  Future<void> _deleteSingle(String username) async {
    await ref.read(analysisRepositoryProvider).removeSearchHistory(username);
    ref.invalidate(searchHistoryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(localeProvider).languageCode;
    final historyAsync = ref.watch(searchHistoryProvider);
    String t(String k) => Strings.tr(k, lang: lang);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('history.title'),
                        style: AppTypography.h1.copyWith(
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t('history.subtitle'),
                        style: AppTypography.body.copyWith(
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                    ],
                  ),
                  if (_selectionMode)
                    TextButton(
                      onPressed: _exitSelection,
                      child: Text(t('history.cancel')),
                    ),
                ],
              ),
            ),
            Expanded(
              child: historyAsync.when(
                data: (profiles) {
                  if (profiles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 80,
                            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t('history.empty'),
                            style: AppTypography.body.copyWith(
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t('history.empty_hint'),
                            style: AppTypography.caption.copyWith(
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(searchHistoryProvider.future),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                '${profiles.length} ${t('history.profiles')}',
                                style: AppTypography.caption.copyWith(
                                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                ),
                              ),
                              const Spacer(),
                              if (_selectionMode && _selected.isNotEmpty)
                                TextButton.icon(
                                  onPressed: _deleteSelected,
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  label: Text('${t('history.delete_selected')} (${_selected.length})'),
                                ),
                              if (!_selectionMode)
                                TextButton.icon(
                                  onPressed: _clearAll,
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  label: Text(t('history.clear')),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: profiles.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final profile = profiles[index];
                              final selected = _selected.contains(profile.username);

                              return Dismissible(
                                key: ValueKey(profile.username),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) async {
                                  await _deleteSingle(profile.username);
                                  return false;
                                },
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.delete_outline, color: Colors.white),
                                ),
                                child: GlassCard(
                                  onTap: () {
                                    if (_selectionMode) {
                                      _toggleSelection(profile.username);
                                    } else {
                                      ref.read(analysisNotifierProvider.notifier).analyzeProfile(profile.username);
                                      context.go('/');
                                    }
                                  },
                                  onLongPress: () {
                                    if (!_selectionMode) {
                                      setState(() => _selectionMode = true);
                                    }
                                    _toggleSelection(profile.username);
                                  },
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      if (_selectionMode) ...[
                                        Checkbox(
                                          value: selected,
                                          onChanged: (_) => _toggleSelection(profile.username),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      ProfileAvatar(
                                        imageUrl: profile.profilePicUrl,
                                        size: 52,
                                        initials: profile.username[0],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  profile.username,
                                                  style: AppTypography.label.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? AppColors.darkText : AppColors.lightText,
                                                  ),
                                                ),
                                                if (profile.isVerified) ...[
                                                  const SizedBox(width: 4),
                                                  Icon(Icons.verified, size: 14, color: AppColors.primary),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              profile.fullName,
                                              style: AppTypography.caption.copyWith(
                                                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                _miniStat(Helpers.formatCount(profile.followersCount), t('stats.followers'), isDark),
                                                const SizedBox(width: 8),
                                                _miniStat(Helpers.formatCount(profile.followingCount), t('stats.following'), isDark),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!_selectionMode)
                                        Icon(Icons.chevron_right, size: 20, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const ListShimmer(itemCount: 6),
                error: (err, _) => Center(child: Text('$err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontSize: 10,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),
      ],
    );
  }
}
