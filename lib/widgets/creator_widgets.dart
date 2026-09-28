import 'package:flutter/material.dart';
import '../models/creator.dart';
import '../screens/creators/creator_profile_screen.dart';
import '../services/creator_service.dart';
import '../theme/app_theme.dart';

void openCreatorProfile(BuildContext context, String creatorId) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreatorProfileScreen(creatorId: creatorId)),
    );

/// Round creator avatar; falls back to the first letter of the name.
class CreatorAvatar extends StatelessWidget {
  final Creator creator;
  final double radius;
  const CreatorAvatar({super.key, required this.creator, this.radius = 18});

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.accent.withValues(alpha: 0.25),
        backgroundImage: creator.avatarUrl.isNotEmpty ? NetworkImage(creator.avatarUrl) : null,
        onBackgroundImageError: creator.avatarUrl.isNotEmpty ? (e, s) {} : null,
        child: creator.avatarUrl.isEmpty
            ? Text(creator.name.isEmpty ? '?' : creator.name[0].toUpperCase(),
                style: AppTheme.orbitron(size: radius * 0.8, weight: FontWeight.w800))
            : null,
      );
}

/// Small blue check shown next to verified creators.
class VerifiedBadge extends StatelessWidget {
  final double size;
  const VerifiedBadge({super.key, this.size = 14});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Verified creator',
        child: Icon(Icons.verified_rounded, color: AppTheme.cyan, size: size),
      );
}

String creatorKindLabel(Creator c) => kCreatorKindLabels[c.kind] ?? c.kind;

/// "By [name] ✓ Podcaster" under a post's title. Loads the creator live
/// and hides itself when the creator is missing or inactive.
class CreatorByline extends StatelessWidget {
  final String creatorId;
  const CreatorByline({super.key, required this.creatorId});

  @override
  Widget build(BuildContext context) => StreamBuilder<Creator?>(
        stream: CreatorService.instance.watchById(creatorId),
        builder: (context, snap) {
          final c = snap.data;
          if (c == null || !c.isActive) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Material(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => openCreatorProfile(context, c.id),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    CreatorAvatar(creator: c, radius: 14),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text('By ${c.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.inter(size: 13, color: Colors.white, weight: FontWeight.w600)),
                    ),
                    if (c.isVerified) ...[const SizedBox(width: 4), const VerifiedBadge()],
                    const SizedBox(width: 6),
                    Text(creatorKindLabel(c), style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 16),
                  ]),
                ),
              ),
            ),
          );
        },
      );
}

/// Horizontal row of round creator bubbles with names and verified badges.
/// Renders nothing when [creators] is empty.
class CreatorBubbleRow extends StatelessWidget {
  final String title;
  final List<Creator> creators;
  final EdgeInsetsGeometry padding;
  const CreatorBubbleRow({
    super.key,
    required this.title,
    required this.creators,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (creators.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTheme.orbitron(size: 10, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: creators.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final c = creators[i];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => openCreatorProfile(context, c.id),
                child: SizedBox(
                  width: 70,
                  child: Column(children: [
                    CreatorAvatar(creator: c, radius: 28),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Flexible(
                        child: Text(c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.inter(size: 11, color: Colors.white, weight: FontWeight.w600)),
                      ),
                      if (c.isVerified) ...[const SizedBox(width: 2), const VerifiedBadge(size: 12)],
                    ]),
                    Text(creatorKindLabel(c),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.inter(size: 10, color: AppTheme.textMuted)),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
