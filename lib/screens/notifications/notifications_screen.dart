import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

/// History of received announcements, newest first. Stored on-device only.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification>? _items;
  Object? _error;
  bool _permissionGranted = true;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    if (pushSupported) {
      _load();
      NotificationService.instance.changes().then((stream) {
        if (!mounted) return;
        _sub = stream.listen((_) => _load());
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await NotificationService.instance.getAll();
      final granted = await NotificationService.instance.isPermissionGranted();
      if (!mounted) return;
      setState(() {
        _items = items;
        _permissionGranted = granted;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _open(AppNotification n) async {
    if (!n.read) await NotificationService.instance.markRead(n.id);
    await _load();
  }

  Future<void> _enable() async {
    await NotificationService.instance.requestPermissionWithExplainer(context);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications', style: AppTheme.orbitron(size: 13)),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (!pushSupported) {
      return _centerMessage(Icons.phone_android,
          'Notifications are available in the mobile app',
          'Install the Android app to receive announcements.');
    }
    if (_error != null) {
      return _centerMessage(
          Icons.error_outline, 'Could not load notifications', 'Please try again later.');
    }
    final items = _items;
    if (items == null) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan),
      );
    }
    return Column(
      children: [
        if (!_permissionGranted) _permissionBanner(),
        Expanded(
          child: items.isEmpty
              ? _centerMessage(Icons.notifications_none, 'No notifications yet',
                  'Announcements from Fandom Verse will appear here.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _row(items[i]),
                ),
        ),
      ],
    );
  }

  Widget _permissionBanner() => Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.orange.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_off_outlined, color: AppTheme.orange, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Notifications are turned off on this device.',
                  style: AppTheme.inter(size: 12, color: Colors.white70)),
            ),
            TextButton(
              onPressed: _enable,
              child: Text('TURN ON',
                  style: AppTheme.orbitron(size: 9, color: AppTheme.orange)),
            ),
          ],
        ),
      );

  Widget _row(AppNotification n) => GestureDetector(
        onTap: () => _open(n),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: n.read ? AppTheme.border : AppTheme.cyan.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (n.read ? Colors.grey : AppTheme.cyan).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.campaign_outlined,
                    color: n.read ? Colors.grey : AppTheme.cyan, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: AppTheme.inter(
                              size: 13,
                              color: Colors.white,
                              weight: n.read ? FontWeight.w500 : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!n.read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: AppTheme.cyan, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    if (n.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(n.body,
                          style: AppTheme.inter(size: 12, color: Colors.grey, height: 1.4)),
                    ],
                    const SizedBox(height: 6),
                    Text(_timeLabel(n.receivedAt),
                        style: AppTheme.inter(size: 10, color: Colors.white38)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  String _timeLabel(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }

  Widget _centerMessage(IconData icon, String title, String subtitle) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.grey, size: 36),
              const SizedBox(height: 10),
              Text(title,
                  textAlign: TextAlign.center,
                  style: AppTheme.orbitron(size: 12, color: Colors.grey, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: AppTheme.inter(size: 11, color: Colors.grey)),
            ],
          ),
        ),
      );
}
