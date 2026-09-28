import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../../controllers/beginner_hub/beginner_hub_controller.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';
import '../../explore/beginner_fan_hub_screen.dart';

/// "Start here" card at the top of Home for new fans. It opens the Beginner
/// Fan Hub and shows checklist progress; it hides itself once every step is
/// done or the fan closes it (both remembered on the device).
class NewFanCard extends StatefulWidget {
  const NewFanCard({super.key});

  @override
  State<NewFanCard> createState() => _NewFanCardState();
}

class _NewFanCardState extends State<NewFanCard> {
  final _controller = const BeginnerHubController();
  late final Future<Box> _flags = BeginnerHubController.openFlags();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Box>(
      future: _flags,
      builder: (context, snap) {
        final box = snap.data;
        if (box == null) return const SizedBox.shrink();
        return ValueListenableBuilder<Box>(
          valueListenable: box.listenable(keys: [
            BeginnerHubController.readGuideKey,
            BeginnerHubController.openedGlossaryKey,
            BeginnerHubController.homeCardDismissedKey,
          ]),
          builder: (context, flags, _) => ValueListenableBuilder<UserData?>(
            valueListenable: AuthService.instance.userNotifier,
            builder: (context, user, _) {
              final steps = _controller.checklist(user, flags);
              if (flags.get(BeginnerHubController.homeCardDismissedKey) == true ||
                  _controller.allDone(steps)) {
                return const SizedBox.shrink();
              }
              return _card(steps);
            },
          ),
        );
      },
    );
  }

  Widget _card(List<HubStep> steps) {
    final done = steps.where((s) => s.done).length;
    final next = steps.firstWhere((s) => !s.done);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BeginnerFanHubScreen()),
          ),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.accent.withValues(alpha: 0.35),
                  AppTheme.cyan.withValues(alpha: 0.15),
                ],
              ),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.55)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accent.withValues(alpha: 0.3),
                  ),
                  child: const Icon(Icons.rocket_launch_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NEW HERE? START HERE',
                          style: AppTheme.orbitron(size: 12, letterSpacing: 0.8)),
                      const SizedBox(height: 4),
                      Text('Find fandoms you\'ll love, read an easy intro and learn the lingo.',
                          style: AppTheme.inter(size: 12, color: Colors.white70, height: 1.4)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (var i = 0; i < steps.length; i++)
                            Expanded(
                              child: Container(
                                height: 4,
                                margin: EdgeInsets.only(right: i == steps.length - 1 ? 0 : 4),
                                decoration: BoxDecoration(
                                  color: steps[i].done ? AppTheme.cyan : Colors.white24,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('$done of ${steps.length} steps · Next: ${next.title}',
                          style: AppTheme.inter(
                              size: 11, color: AppTheme.cyan, weight: FontWeight.w600)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      tooltip: 'Hide',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                      onPressed: BeginnerHubController.dismissHomeCard,
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white70),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
