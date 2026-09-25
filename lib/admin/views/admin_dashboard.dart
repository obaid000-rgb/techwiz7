import 'package:flutter/material.dart';
import '../../services/category_service.dart';
import '../../services/event_service.dart';
import '../../services/merchandise_service.dart';
import '../../services/post_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard_outlined, color: AppTheme.accent, size: 18),
              const SizedBox(width: 8),
              Text('Overview', style: AppTheme.orbitron(size: 14, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Live counts from Firestore collections',
              style: AppTheme.inter(size: 11, color: Colors.grey)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _CountCard(
                label: 'Users',
                icon: Icons.people_outline,
                color: AppTheme.accent,
                stream: UserService.instance.watchUsers().map((l) => l.length),
              ),
              _CountCard(
                label: 'Posts',
                icon: Icons.article_outlined,
                color: AppTheme.cyan,
                stream: PostService.instance.watchPosts().map((l) => l.length),
              ),
              _CountCard(
                label: 'Merchandise',
                icon: Icons.shopping_bag_outlined,
                color: AppTheme.orange,
                stream:
                    MerchandiseService.instance.watchMerchandise().map((l) => l.length),
              ),
              _CountCard(
                label: 'Events',
                icon: Icons.event_outlined,
                color: AppTheme.pink,
                stream: EventService.instance.watchEvents().map((l) => l.length),
              ),
              _CountCard(
                label: 'Categories',
                icon: Icons.category_outlined,
                color: AppTheme.orange,
                stream:
                    CategoryService.instance.watchCategories().map((l) => l.length),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Stream<int> stream;

  const _CountCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: StreamBuilder<int>(
          stream: stream,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final hasError = snapshot.hasError;
            final count = snapshot.data;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: color),
                  )
                else if (hasError)
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 18)
                else
                  Text(
                    '${count ?? 0}',
                    style: AppTheme.orbitron(
                        size: 28,
                        color: Colors.white,
                        weight: FontWeight.w800),
                  ),
                const SizedBox(height: 4),
                Text(label,
                    style: AppTheme.inter(size: 11, color: Colors.grey)),
              ],
            );
          },
        ),
      ),
    );
  }
}
