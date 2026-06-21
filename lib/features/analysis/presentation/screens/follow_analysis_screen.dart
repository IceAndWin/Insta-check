import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/localization/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/datasources/analysis_api_source.dart';
import '../providers/analysis_provider.dart';
import '../../domain/entities/follow_analysis.dart';

class FollowAnalysisScreen extends ConsumerWidget {
  final String username;

  const FollowAnalysisScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(followAnalysisProvider(username));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(localeProvider).languageCode;
    String t(String key) => Strings.tr(key, lang: lang);

    return Scaffold(
      appBar: AppBar(
        title: Text('@$username'),
        actions: [
          if (analysisAsync.valueOrNull != null)
            IconButton(
              onPressed: () => _shareSummary(analysisAsync.value!, lang),
              icon: const Icon(Icons.share_outlined),
              tooltip: t('follow.share_summary'),
            ),
        ],
      ),
      body: analysisAsync.when(
        data: (analysis) => _buildContent(analysis, isDark, lang),
        loading: () => const FollowAnalysisShimmer(),
        error: (err, _) {
          String msg;
          if (err is ApiException) {
            switch (err.code) {
              case 'USER_NOT_FOUND':
                msg = t('error.user_not_found');
                break;
              case 'CHALLENGE_REQUIRED':
                msg = t('error.challenge_required');
                break;
              case 'RATE_LIMITED':
                msg = t('error.rate_limited');
                break;
              case 'PRIVATE_ACCOUNT':
                msg = t('error.private_account');
                break;
              default:
                msg = err.message;
            }
          } else {
            msg = err.toString();
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        err is ApiException && err.code == 'PRIVATE_ACCOUNT'
                            ? Icons.lock_outline
                            : Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: Text(
                          msg,
                          textAlign: TextAlign.center,
                          style: AppTypography.body.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(FollowAnalysis analysis, bool isDark, String lang) {
    String t(String key) => Strings.tr(key, lang: lang);

    final meta = analysis.metadata;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (meta != null) ...[
            _buildMetadataBadge(meta, isDark, lang),
            const SizedBox(height: 12),
          ],
          _buildStatRow(analysis, isDark, lang),
          const SizedBox(height: 24),
          _ExpandableSection(
            title: t('follow.not_following_back'),
            followers: analysis.notFollowingBack,
            accentColor: AppColors.error,
            isDark: isDark,
            lang: lang,
          ),
          const SizedBox(height: 16),
          _ExpandableSection(
            title: t('follow.not_followed'),
            followers: analysis.notFollowedByUser,
            accentColor: AppColors.accent,
            isDark: isDark,
            lang: lang,
          ),
          const SizedBox(height: 16),
          _ExpandableSection(
            title: t('follow.mutual'),
            followers: analysis.mutualFollowers,
            accentColor: AppColors.success,
            isDark: isDark,
            lang: lang,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _summaryText(FollowAnalysis analysis, String lang) {
    final t = Strings.tr;
    return [
      'InstaCheck — @$username',
      '',
      '${t('follow.not_following_back', lang: lang)}: ${analysis.totalNotFollowingBack}',
      '${t('follow.mutual', lang: lang)}: ${analysis.totalMutual}',
      '${t('follow.not_followed', lang: lang)}: ${analysis.totalNotFollowedByUser}',
    ].join('\n');
  }

  Future<void> _shareSummary(FollowAnalysis analysis, String lang) async {
    await Share.share(_summaryText(analysis, lang));
  }

  Widget _buildStatRow(FollowAnalysis analysis, bool isDark, String lang) {
    String t(String key) => Strings.tr(key, lang: lang);

    return Row(
      children: [
        _miniStat(t('follow.not_following_back').split(' ')[0], analysis.totalNotFollowingBack, AppColors.error, isDark),
        const SizedBox(width: 8),
        _miniStat(t('follow.mutual').split(' ')[0], analysis.totalMutual, AppColors.success, isDark),
        const SizedBox(width: 8),
        _miniStat(t('follow.not_followed').split(' ')[0], analysis.totalNotFollowedByUser, AppColors.accent, isDark),
      ],
    );
  }

  Widget _buildMetadataBadge(AnalysisMetadata meta, bool isDark, String lang) {
    final color = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            meta.isApproximate
                ? 'Sampled ${meta.sampled} (~${meta.totalAvailable} available)'
                : 'Sampled ${meta.sampled}',
            style: AppTypography.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int count, Color color, bool isDark) {
    return Expanded(
      child: GlassCard(
        child: Column(
          children: [
            Text(count.toString(), style: AppTypography.h3.copyWith(color: color)),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  final String title;
  final List<Follower> followers;
  final Color accentColor;
  final bool isDark;
  final String lang;

  const _ExpandableSection({
    required this.title,
    required this.followers,
    required this.accentColor,
    required this.isDark,
    required this.lang,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _expanded = false;
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final t = Strings.tr;
    final followers = widget.followers;
    final isCapped = followers.length >= 300;
    final badgeText = isCapped ? '300+' : followers.length.toString();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: AppTypography.caption.copyWith(
                    color: widget.accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTypography.subtitle.copyWith(
                    color: widget.isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: '',
                onSelected: (value) async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (value == 'copy') {
                    await Clipboard.setData(
                      ClipboardData(text: followers.map((e) => e.username).join('\n')),
                    );
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(t('follow.copied', lang: widget.lang))),
                      );
                    }
                  } else if (value == 'share') {
                    await Share.share(
                      followers.map((e) => '@${e.username}').join('\n'),
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'copy',
                    child: Text(t('follow.copy_usernames', lang: widget.lang)),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Text(t('follow.share_usernames', lang: widget.lang)),
                  ),
                ],
                icon: Icon(
                  Icons.more_horiz,
                  color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
            ],
          ),
            ],
          ),
          if (followers.isEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 32,
                    color: (widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext).withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('follow.empty', lang: widget.lang),
                    style: AppTypography.body.copyWith(
                      color: (widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext).withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            if (_expanded) ...[
              SizedBox(
                height: 400,
                child: Scrollbar(
                  thumbVisibility: true,
                  thickness: 6,
                  radius: const Radius.circular(3),
                  controller: _scrollController,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: followers.length,
                    itemBuilder: (_, i) => _followerTile(followers[i]),
                  ),
                ),
              ),
            ] else
              ...followers.take(10).map((f) => _followerTile(f)),
            if (followers.length > 10) ...[
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded
                        ? t('follow.show_less', lang: widget.lang)
                        : Strings.trWithArgs('follow.more', (followers.length - 10).toString(), lang: widget.lang),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _followerTile(Follower follower) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ProfileAvatar(
            imageUrl: follower.profilePicUrl,
            size: 28,
            initials: follower.username[0],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      follower.username,
                      style: AppTypography.caption.copyWith(
                        color: widget.isDark ? AppColors.darkText : AppColors.lightText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (follower.isVerified) ...[
                      const SizedBox(width: 3),
                      Icon(Icons.verified, size: 12, color: AppColors.primary),
                    ],
                  ],
                ),
                if (follower.fullName != null)
                  Text(
                    follower.fullName!,
                    style: AppTypography.caption.copyWith(
                      color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
