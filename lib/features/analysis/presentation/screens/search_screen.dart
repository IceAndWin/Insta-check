import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/analysis_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  bool _isPrivateError = false;
  int _privateErrorCount = 0;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -3), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 1),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _triggerPrivateError() {
    HapticFeedback.heavyImpact();
    _privateErrorCount++;
    setState(() => _isPrivateError = true);
    _shakeController.forward(from: 0);
    final myCount = _privateErrorCount;
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && myCount == _privateErrorCount) {
        setState(() => _isPrivateError = false);
      }
    });
  }

  void _search() {
    if (!_formKey.currentState!.validate()) return;
    final username = _searchController.text.trim();
    ref.read(analysisNotifierProvider.notifier).analyzeProfile(username);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(localeProvider).languageCode;
    final analysisState = ref.watch(analysisNotifierProvider);
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
                t('search.title'),
                style: AppTypography.h1.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t('search.subtitle'),
                style: AppTypography.body.copyWith(
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _searchController,
                        validator: Validators.instagramUsername,
                        style: AppTypography.body.copyWith(
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                        decoration: InputDecoration(
                          hintText: t('search.hint'),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        textInputAction: TextInputAction.search,
                        onFieldSubmitted: (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GradientButton(
                      label: t('search.button'),
                      onPressed: _search,
                      isLoading: analysisState.isLoading,
                      fullWidth: false,
                      height: 52,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              analysisState.when(
                data: (profile) {
                  if (profile == null) return _buildHistorySection(isDark, lang);
                  return _buildProfileResult(profile, isDark, lang);
                },
                loading: () => const ProfileShimmer(),
                error: (err, _) => _buildError(err.toString(), isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection(bool isDark, String lang) {
    String t(String key) => Strings.tr(key, lang: lang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('search.saved_accounts'),
          style: AppTypography.subtitle.copyWith(
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        const SizedBox(height: 16),
        ref.watch(savedAccountsProvider).when(
              data: (accounts) {
                if (accounts.isEmpty) {
                  return GlassCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 64,
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              t('search.no_saved'),
                              style: AppTypography.body.copyWith(
                                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: accounts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return GlassCard(
                      onTap: () {
                        ref.read(analysisNotifierProvider.notifier).analyzeProfile(account.username);
                      },
                      child: Row(
                        children: [
                          ProfileAvatar(
                            imageUrl: account.profilePicUrl,
                            initials: account.username[0],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.username,
                                  style: AppTypography.label.copyWith(
                                    color: isDark ? AppColors.darkText : AppColors.lightText,
                                  ),
                                ),
                                Text(
                                  account.fullName,
                                  style: AppTypography.caption.copyWith(
                                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const ProfileShimmer(),
              error: (_, __) => const SizedBox(),
            ),
      ],
    );
  }

  Widget _buildProfileResult(dynamic profile, bool isDark, String lang) {
    String t(String key) => Strings.tr(key, lang: lang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          child: Column(
            children: [
              ProfileAvatar(
                imageUrl: profile.profilePicUrl,
                size: 96,
                initials: profile.username[0],
              ),
              const SizedBox(height: 16),
              Text(
                profile.username,
                style: AppTypography.h3.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.fullName,
                style: AppTypography.body.copyWith(
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
              if (profile.biography != null && profile.biography!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  profile.biography!,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
                const SizedBox(height: 8),
              ] else
                const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (profile.isVerified)
                    _buildBadge(t('profile.verified'), AppColors.success)
                  else if (!profile.isPrivate)
                    _buildBadge(t('profile.public'), AppColors.primary),
                  if (profile.isPrivate) ...[
                    const SizedBox(width: 8),
                    _buildBadge(t('profile.private'), AppColors.error),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCountColumn(t('profile.posts'), profile.postsCount.toString(), isDark),
                  _buildCountColumn(t('profile.followers'), profile.followersCount.toString(), isDark),
                  _buildCountColumn(t('profile.following'), profile.followingCount.toString(), isDark),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (profile.isPrivate)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 20, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t('profile.private_hint'),
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (_, child) => Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: child,
            ),
            child: GradientButton(
              label: t('search.view_follow'),
              icon: _isPrivateError ? Icons.lock_outline : Icons.people_outlined,
              gradient: _isPrivateError ? [AppColors.error, AppColors.error] : null,
              onPressed: profile.isPrivate
                  ? () => _triggerPrivateError()
                  : () => context.push('/follow-analysis/${profile.username}'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(analysisNotifierProvider.notifier).clearResult();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            icon: const Icon(Icons.search_off),
            label: Text(t('search.search_another')),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCountColumn(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.subtitle.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),
      ],
    );
  }

  Widget _buildError(String error, bool isDark) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }
}
