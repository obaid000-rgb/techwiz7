import 'package:flutter/material.dart';
import '../models/post.dart';
import '../screens/explore/beginner_fan_hub_screen.dart';
import '../screens/shop/shop_tab.dart' show showGuestLoginSheet;
import '../services/auth_service.dart';
import '../services/xp_service.dart';
import '../theme/app_theme.dart';
import '../utils/levels.dart';

/// How each XP action is described on the locked screen (values come from
/// XpService.points, so they can't drift).
String _xpActionLabel(XpAction a) => switch (a) {
      XpAction.dailyOpen => 'Open the app (once a day)',
      XpAction.firstPostOpen => 'Read a post for the first time',
      XpAction.firstFollow => 'Follow a new fandom',
      XpAction.aiQuestion => 'Ask the Fan Helper (up to ${XpService.aiDailyLimit} a day)',
      XpAction.order => 'Place a shop order',
    };

/// The screen shown instead of a Deep Dive post to anyone below Level
/// [DEEP_DIVE_LEVEL] (and guests). A teaser: the title, cover and fandom
/// stay visible, the body, media, video and audio never load.
class DeepDiveLockedView extends StatelessWidget {
  final Post post;
  /// Network image online, the saved file for an offline copy; null = none.
  final ImageProvider? cover;

  const DeepDiveLockedView({super.key, required this.post, this.cover});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.card,
            flexibleSpace: FlexibleSpaceBar(
              background: cover == null
                  ? Container(color: AppTheme.card)
                  : Image(
                      image: cover!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, e, st) => Container(color: AppTheme.card)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ValueListenableBuilder<UserData?>(
                valueListenable: AuthService.instance.userNotifier,
                builder: (context, user, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.fandomName.isNotEmpty) ...[
                      Text(post.fandomName.toUpperCase(),
                          style: AppTheme.orbitron(size: 10, color: AppTheme.cyan, weight: FontWeight.w700)),
                      const SizedBox(height: 6),
                    ],
                    Text(post.title,
                        style: AppTheme.inter(size: 20, weight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 20),
                    _lockCard(context, user),
                    const SizedBox(height: 20),
                    _howToEarn(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const BeginnerFanHubScreen())),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.cyan),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.school_outlined, color: AppTheme.cyan, size: 18),
                        label: Text('VISIT THE BEGINNER FAN HUB',
                            style: AppTheme.orbitron(size: 10, color: AppTheme.cyan, weight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockCard(BuildContext context, UserData? user) {
    final target = kLevelThresholds[DEEP_DIVE_LEVEL - 1];
    final xp = user?.xp ?? 0;
    final level = levelFor(xp);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.orange.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_rounded, color: AppTheme.orange, size: 36),
          const SizedBox(height: 10),
          Text(
            user == null
                ? 'Sign in and reach Level $DEEP_DIVE_LEVEL to unlock Deep Dive'
                : 'Deep Dive unlocks at Level $DEEP_DIVE_LEVEL. '
                    "You're Level $level with $xp XP. "
                    'Earn ${xpToLevel(xp, DEEP_DIVE_LEVEL)} more XP to unlock.',
            textAlign: TextAlign.center,
            style: AppTheme.inter(size: 14, color: Colors.white, weight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (xp / target).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppTheme.bg,
              color: AppTheme.orange,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level $level', style: AppTheme.inter(size: 11, color: AppTheme.textMuted)),
              Text('${xp.clamp(0, target)} / $target XP', style: AppTheme.inter(size: 11, color: AppTheme.textMuted)),
              Text('Level $DEEP_DIVE_LEVEL', style: AppTheme.inter(size: 11, color: AppTheme.textMuted)),
            ],
          ),
          if (user == null) ...[
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => showGuestLoginSheet(context, feature: 'Deep Dive'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cyan,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('LOG IN',
                  style: AppTheme.orbitron(size: 11, color: Colors.black, weight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _howToEarn() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HOW TO EARN XP', style: AppTheme.orbitron(size: 11, weight: FontWeight.w700)),
            const SizedBox(height: 10),
            for (final a in XpAction.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(_xpActionLabel(a),
                            style: AppTheme.inter(size: 13, color: AppTheme.textSecondary))),
                    Text('+${XpService.points[a]} XP',
                        style: AppTheme.inter(size: 13, color: AppTheme.cyan, weight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
        ),
      );
}

/// A card's two-line text preview. For a Deep Dive post the viewer can't
/// open yet it shows a lock line instead, so no Deep Dive text leaks into
/// lists (the title and cover stay, as a teaser).
class PostExcerpt extends StatelessWidget {
  final Post post;
  final TextStyle style;
  final int maxLines;

  const PostExcerpt({super.key, required this.post, required this.style, this.maxLines = 2});

  @override
  Widget build(BuildContext context) {
    if (!isDeepDive(post)) {
      return Text(post.content, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: style);
    }
    return ValueListenableBuilder<UserData?>(
      valueListenable: AuthService.instance.userNotifier,
      builder: (context, user, _) => canViewDeepDive(user)
          ? Text(post.content, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: style)
          : Text('Deep Dive · unlocks at Level $DEEP_DIVE_LEVEL',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style.copyWith(color: AppTheme.orange, fontStyle: FontStyle.italic)),
    );
  }
}
