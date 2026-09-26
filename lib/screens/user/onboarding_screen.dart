import 'package:flutter/material.dart';
import '../../models/app_category.dart';
import '../../services/auth_service.dart';
import '../../services/category_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';

/// Collects interests (categories) and a profile badge. Two modes:
/// - [OnboardingScreen]: signed-in user with no saved categories (see
///   UserData.hasOnboarded) — writes both to their Firestore user document.
/// - [OnboardingScreen.preLogin]: first-run flow before any account exists —
///   hands the selection to [onPreLoginComplete] instead of writing anywhere.
class OnboardingScreen extends StatefulWidget {
  final UserData? user;
  final Future<void> Function(List<String> categories, String badge)?
      onPreLoginComplete;

  const OnboardingScreen({super.key, required UserData this.user})
      : onPreLoginComplete = null;

  const OnboardingScreen.preLogin({super.key, required this.onPreLoginComplete})
      : user = null;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final Set<String> _selectedCategoryKeys = {};
  String? _selectedBadge;
  bool _saving = false;
  String? _error;

  Future<void> _finish() async {
    if (_selectedCategoryKeys.isEmpty) {
      setState(() => _error = 'Pick at least one interest to continue.');
      return;
    }
    if (_selectedBadge == null) {
      setState(() => _error = 'Pick a badge to continue.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final user = widget.user;
      if (user == null) {
        await widget.onPreLoginComplete!(
            _selectedCategoryKeys.toList(), _selectedBadge!);
        return;
      }
      final updated = user.copyWith(
        categories: _selectedCategoryKeys.toList(),
        badge: _selectedBadge,
      );
      await UserService.instance.updateUser(updated);
      AuthService.instance.userNotifier.value = updated;
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WELCOME TO FANDOM VERSE',
                  style: AppTheme.orbitron(size: 16, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Pick a few things so we can tailor your feed.',
                  style: AppTheme.inter(size: 13, color: Colors.grey)),
              const SizedBox(height: 28),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Interests',
                          style: AppTheme.inter(size: 12, color: Colors.grey)),
                      const SizedBox(height: 10),
                      _categoryGrid(),
                      const SizedBox(height: 28),
                      Text('Your Badge',
                          style: AppTheme.inter(size: 12, color: Colors.grey)),
                      const SizedBox(height: 10),
                      _badgeGrid(),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: AppTheme.inter(size: 12, color: Colors.redAccent)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _finish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('START EXPLORING',
                          style: AppTheme.orbitron(
                              size: 12,
                              color: Colors.white,
                              weight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryGrid() {
    return StreamBuilder<List<AppCategory>>(
      stream: CategoryService.instance.watchActiveCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan),
            ),
          );
        }
        final cats = List<AppCategory>.from(snapshot.data ?? [])
          ..sort((a, b) => a.order.compareTo(b.order));
        if (cats.isEmpty) {
          return Text('No categories available yet.',
              style: AppTheme.inter(size: 12, color: Colors.grey));
        }
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: cats.map((c) {
            final selected = _selectedCategoryKeys.contains(c.key);
            return GestureDetector(
              onTap: () => setState(() {
                selected
                    ? _selectedCategoryKeys.remove(c.key)
                    : _selectedCategoryKeys.add(c.key);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.accent.withValues(alpha: 0.2) : AppTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: selected ? AppTheme.accent : AppTheme.border),
                ),
                child: Text(
                  c.name,
                  style: AppTheme.inter(
                    size: 12,
                    color: selected ? AppTheme.accent : Colors.white70,
                    weight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _badgeGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: kProfileBadges.map((b) {
        final selected = _selectedBadge == b;
        return GestureDetector(
          onTap: () => setState(() => _selectedBadge = b),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppTheme.cyan.withValues(alpha: 0.2) : AppTheme.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? AppTheme.cyan : AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.military_tech,
                    size: 14, color: selected ? AppTheme.cyan : Colors.grey),
                const SizedBox(width: 6),
                Text(
                  b,
                  style: AppTheme.inter(
                    size: 12,
                    color: selected ? AppTheme.cyan : Colors.white70,
                    weight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
