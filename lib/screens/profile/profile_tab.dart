import 'package:flutter/material.dart';
import '../../models/app_category.dart';
import '../../services/auth_service.dart';
import '../../services/category_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/levels.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/guest_prompt.dart';
import '../../models/fandom.dart';
import '../../services/fandom_service.dart';
import '../events/my_agenda_screen.dart';
import '../shop/wishlist_screen.dart';
import 'following_screen.dart';
import 'widgets/my_fandoms_card.dart';
import 'edit_profile_screen.dart';
import '../info/about_us_screen.dart';
import '../info/contact_us_screen.dart';
import '../notifications/notifications_screen.dart';
import 'purchase_history_screen.dart';
import 'saved_bookmarks_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserData?>(
      valueListenable: AuthService.instance.userNotifier,
      builder: (context, user, _) {
        if (user == null) {
          // Guests can't open the profile, but About/Contact stay reachable.
          return Column(children: [
            const Expanded(child: GuestPrompt(feature: 'Your profile and saved content')),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                    ),
                    icon: const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.cyan),
                    label: Text('About Us', style: AppTheme.inter(size: 13, color: AppTheme.cyan)),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                    ),
                    icon: const Icon(Icons.mail_outline_rounded, size: 18, color: AppTheme.cyan),
                    label: Text('Contact Us', style: AppTheme.inter(size: 13, color: AppTheme.cyan)),
                  ),
                ]),
              ),
            ),
          ]);
        }
        return _ProfileContent(user: user);
      },
    );
  }
}

class _ProfileContent extends StatefulWidget {
  final UserData user;
  const _ProfileContent({required this.user});

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  late final Stream<List<AppCategory>> _categories =
      CategoryService.instance.watchCategories();

  /// Shows [apply] immediately, writes it with [save] (a single-field
  /// Firestore update), and rolls back with a message if the write fails.
  Future<void> _saveField(
    UserData Function(UserData u) apply,
    UserData Function(UserData u) revert,
    Future<void> Function(String uid) save,
    String failMessage,
  ) async {
    final user = AuthService.instance.currentUser ?? widget.user;
    AuthService.instance.userNotifier.value = apply(user);
    try {
      await save(user.uid);
    } catch (_) {
      final current = AuthService.instance.currentUser;
      if (current != null) AuthService.instance.userNotifier.value = revert(current);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failMessage)));
      }
    }
  }

  Future<void> _editFandoms(List<AppCategory> allCategories) async {
    final active = allCategories.where((c) => c.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final selected = Set<String>.from(widget.user.categories);
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Fandoms', style: AppTheme.orbitron(size: 13)),
                const SizedBox(height: 4),
                Text('Pick the fandoms you follow. Used to tailor your feed.',
                    style: AppTheme.inter(size: 11, color: Colors.grey)),
                const SizedBox(height: 14),
                if (active.isEmpty)
                  Text('No categories available yet.',
                      style: AppTheme.inter(size: 12, color: Colors.grey))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: active.map((c) {
                      final on = selected.contains(c.key);
                      return FilterChip(
                        label: Text(c.name),
                        selected: on,
                        onSelected: (v) => setSheet(() {
                          v ? selected.add(c.key) : selected.remove(c.key);
                        }),
                        showCheckmark: true,
                        checkmarkColor: Colors.white,
                        selectedColor: AppTheme.accent.withValues(alpha: 0.35),
                        backgroundColor: AppTheme.bg,
                        side: BorderSide(color: on ? AppTheme.accent : AppTheme.border),
                        labelStyle: AppTheme.inter(
                            size: 12,
                            color: on ? Colors.white : Colors.white70,
                            weight: on ? FontWeight.w700 : FontWeight.w400),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // At least one is required — an empty list would send the
                    // user back through the Select Fandoms screen.
                    onPressed: selected.isEmpty ? null : () => Navigator.pop(ctx, selected.toList()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      disabledBackgroundColor: AppTheme.border,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(selected.isEmpty ? 'PICK AT LEAST ONE' : 'SAVE',
                        style: AppTheme.orbitron(size: 10, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null) return;
    final previous = List<String>.from(widget.user.categories);
    await _saveField(
      (u) => u.copyWith(categories: result),
      (u) => u.copyWith(categories: previous),
      (uid) => UserService.instance.setCategories(uid, result),
      'Could not save your fandoms. Try again.',
    );
  }

  Widget _fandomsCard(UserData user) => StreamBuilder<List<AppCategory>>(
        stream: _categories,
        builder: (context, snapshot) => MyFandomsCard(
          categoryKeys: user.categories,
          categories: snapshot.data,
          hasError: snapshot.hasError,
          onEdit: snapshot.hasData ? () => _editFandoms(snapshot.data!) : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Display only — changed from Edit Profile.
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppTheme.cyan, AppTheme.accent]),
            ),
            child: AvatarView.user(user, radius: 46),
          ),
          const SizedBox(height: 14),
          Text(user.name,
              style: AppTheme.orbitron(size: 18, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(user.email, style: AppTheme.inter(size: 12, color: Colors.grey)),
          if (user.badge.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.cyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.military_tech, color: AppTheme.cyan, size: 13),
                  const SizedBox(width: 5),
                  Text(user.badge,
                      style: AppTheme.orbitron(size: 9, color: AppTheme.cyan)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          _levelCard(user.xp),
          const SizedBox(height: 12),

          // Stats row — every number is real data and opens its list.
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _FollowingStat(
                    key: ValueKey(user.followedFandomIds.join(',')),
                    fandomIds: user.followedFandomIds,
                    builder: (count) => _stat('$count', 'Following',
                        () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const FollowingScreen()))),
                  ),
                ),
                Container(width: 1, height: 32, color: AppTheme.border),
                Expanded(
                  child: _stat('${user.bookmarkedPostIds.length}', 'Saved',
                      () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SavedBookmarksScreen()))),
                ),
                Container(width: 1, height: 32, color: AppTheme.border),
                Expanded(
                  child: _stat('${user.wishlistedProductIds.length}', 'Wishlist',
                      () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const WishlistScreen()))),
                ),
                Container(width: 1, height: 32, color: AppTheme.border),
                Expanded(
                  child: _stat('${user.savedEventIds.length}', 'Agenda',
                      () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const MyAgendaScreen()))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.border),
                backgroundColor: AppTheme.card,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.edit_rounded, color: AppTheme.cyan, size: 16),
              label: Text('Edit Profile',
                  style: AppTheme.inter(size: 13, color: Colors.white, weight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),

          // Bio — read-only here; edited from Edit Profile.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              user.bio.isEmpty ? 'No bio yet.' : user.bio,
              style: AppTheme.inter(
                size: 12,
                color: user.bio.isEmpty ? Colors.grey : Colors.white70,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _fandomsCard(user),
          const SizedBox(height: 24),

          _groupLabel('YOUR LIBRARY'),
          _libraryTile(
            icon: Icons.bookmark_rounded,
            color: AppTheme.cyan,
            title: 'Bookmarks',
            count: user.bookmarkedPostIds.length,
            description: 'Posts you bookmark, saved on this phone.',
            badgeIcon: Icons.wifi_off,
            badge: 'Works without internet',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedBookmarksScreen()),
            ),
          ),
          const SizedBox(height: 14),

          _groupLabel('ACCOUNT'),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                _menuTile(
                  Icons.receipt_long_outlined,
                  'Purchase history',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PurchaseHistoryScreen(uid: user.uid)),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.border),
                _menuTile(
                  Icons.notifications_none,
                  'Notifications',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.border),
                _menuTile(
                  Icons.info_outline_rounded,
                  'About Us',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.border),
                _menuTile(
                  Icons.mail_outline_rounded,
                  'Contact Us',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout — calls signOut() only; top bar and this screen update via ValueListenableBuilder
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => AuthService.instance.signOut(),
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
              label: Text('LOG OUT',
                  style: AppTheme.orbitron(size: 11, color: Colors.redAccent, weight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelCard(int xp) {
    final level = levelFor(xp);
    final max = level >= kMaxLevel;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppTheme.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Level $level · ${levelName(level)}',
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.orbitron(size: 13, weight: FontWeight.w700)),
              ),
              Text('$xp XP',
                  style: AppTheme.inter(size: 12, color: AppTheme.cyan, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressToNextLevel(xp),
              minHeight: 8,
              backgroundColor: AppTheme.bg,
              color: max ? AppTheme.orange : AppTheme.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            max ? 'Max level' : '${xpToNextLevel(xp)} XP to Level ${level + 1}',
            style: AppTheme.inter(size: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _stat(String val, String label, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: '$val $label',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Text(val, style: AppTheme.orbitron(size: 17, color: AppTheme.cyan, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(label, style: AppTheme.inter(size: 12, color: AppTheme.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _groupLabel(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Text(text,
              style: AppTheme.orbitron(size: 12, color: AppTheme.textSecondary, letterSpacing: 1)),
        ),
      );

  Widget _libraryTile({
    required IconData icon,
    required Color color,
    required String title,
    required int count,
    required String description,
    required IconData badgeIcon,
    required String badge,
    required VoidCallback onTap,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(
                            child: Text(title,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.inter(size: 15, weight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          Text('$count',
                              style: AppTheme.inter(size: 12, weight: FontWeight.w600, color: AppTheme.textMuted)),
                        ]),
                        const SizedBox(height: 4),
                        Text(description,
                            style: AppTheme.inter(size: 12, color: AppTheme.textSecondary, height: 1.4)),
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(badgeIcon, color: color, size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(badge,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.inter(size: 11, weight: FontWeight.w600, color: color)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _menuTile(IconData icon, String title, VoidCallback onTap) {
    // Own transparent Material so the tap ripple shows on the card behind it.
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        minTileHeight: 56,
        leading: Icon(icon, color: AppTheme.cyan, size: 22),
        title: Text(title, style: AppTheme.inter(size: 14, weight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
        onTap: onTap,
      ),
    );
  }
}

/// Live count of the fan's followed fandoms that are still active.
class _FollowingStat extends StatefulWidget {
  final List<String> fandomIds;
  final Widget Function(int count) builder;
  const _FollowingStat({super.key, required this.fandomIds, required this.builder});

  @override
  State<_FollowingStat> createState() => _FollowingStatState();
}

class _FollowingStatState extends State<_FollowingStat> {
  // Held in state so a rebuild doesn't open a new Firestore listener;
  // recreated only when the followed ids actually change.
  Stream<List<Fandom>>? _stream;

  @override
  void initState() {
    super.initState();
    _stream = _watch();
  }

  @override
  void didUpdateWidget(_FollowingStat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameIds(oldWidget.fandomIds, widget.fandomIds)) _stream = _watch();
  }

  Stream<List<Fandom>>? _watch() => widget.fandomIds.isEmpty
      ? null
      : FandomService.instance.watchByIds(widget.fandomIds);

  static bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final stream = _stream;
    if (widget.fandomIds.isEmpty || stream == null) return widget.builder(0);
    return StreamBuilder<List<Fandom>>(
      stream: stream,
      builder: (context, snap) => widget.builder(snap.hasData
          ? snap.data!.where((f) => f.isActive).length
          : widget.fandomIds.length),
    );
  }
}
