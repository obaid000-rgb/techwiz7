import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../screens/notifications/notifications_screen.dart';
import '../theme/app_theme.dart';
import 'first_run_service.dart';

const String kAnnouncementsTopic = 'announcements';
const String kAnnouncementsChannelId = 'announcements';
const String kPriceAlertsChannelId = 'price_alerts';


bool get pushSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);


@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.saveMessage(message);
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.read = false,
  });

  factory AppNotification.fromMap(Map map) => AppNotification(
        id: map['id'] as String,
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        receivedAt:
            DateTime.tryParse(map['receivedAt'] as String? ?? '') ?? DateTime.now(),
        read: map['read'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'receivedAt': receivedAt.toIso8601String(),
        'read': read,
      };
}

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  static const String _boxName = 'notifications';
  static const String _promptShownKey = 'notificationPromptShown';

  /// Lets notification taps navigate from outside the widget tree.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  Future<void>? _hiveReady;
  bool _initialized = false;


  Future<IsolatedBox<Map>> _box() async {
    _hiveReady ??= IsolatedHive.initFlutter();
    await _hiveReady;
    return IsolatedHive.openBox<Map>(_boxName);
  }

  Future<void> init() async {
    if (!pushSupported || _initialized) return;
    _initialized = true;

    await _initLocal();

    FirebaseMessaging.instance
        .subscribeToTopic(kAnnouncementsTopic)
        .catchError((_) {});

    FirebaseMessaging.onMessage.listen((message) async {
      await saveMessage(message);
      final n = message.notification;
      await _local.show(
        id: message.hashCode,
        title: n?.title ?? message.data['title'] as String?,
        body: n?.body ?? message.data['body'] as String?,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            kAnnouncementsChannelId,
            'Announcements',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
            color: AppTheme.accent,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await saveMessage(message);
      openNotificationsScreen();
    });
  }

  Future<void>? _localReady;


  Future<void> _initLocal() => _localReady ??= _doInitLocal();

  Future<void> _doInitLocal() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (_) => openNotificationsScreen(),
    );


    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          kAnnouncementsChannelId,
          'Announcements',
          description: 'News and announcements from Fandom Verse',
          importance: Importance.high,
        ));

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          kPriceAlertsChannelId,
          'Price alerts',
          description: 'Price changes on items in your wishlist',
          importance: Importance.high,
        ));
  }

  Future<bool> launchedFromNotification() async {
    if (!pushSupported) return false;
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      await saveMessage(initial);
      return true;
    }
    final details = await _local.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp ?? false;
  }

  void openNotificationsScreen() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }


  Future<void> showPriceAlert({
    required String productId,
    required String title,
    required String body,
  }) async {
    try {
      await saveLocal(
        id: 'price-$productId-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        body: body,
      );
    } catch (e) {
      debugPrint('Price alert history save failed: $e');
    }
    if (!pushSupported) return;
    await _initLocal();
    await _local.show(
      id: productId.hashCode & 0x7fffffff,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          kPriceAlertsChannelId,
          'Price alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          color: AppTheme.accent,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // ── History ──────────────────────────────────────────────────────────────

  Future<void> saveLocal({required String id, required String title, required String body}) async {
    final box = await _box();
    await box.put(
      id,
      AppNotification(id: id, title: title, body: body, receivedAt: DateTime.now()).toMap(),
    );
  }

  Future<void> saveMessage(RemoteMessage message) async {
    final id = message.messageId ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final box = await _box();
    if (await box.containsKey(id)) return;
    final n = message.notification;
    await box.put(
      id,
      AppNotification(
        id: id,
        title: n?.title ?? message.data['title'] as String? ?? 'Announcement',
        body: n?.body ?? message.data['body'] as String? ?? '',
        receivedAt: message.sentTime ?? DateTime.now(),
      ).toMap(),
    );
  }

  Future<List<AppNotification>> getAll() async {
    final box = await _box();
    return (await box.values)
        .map(AppNotification.fromMap)
        .toList()
      ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
  }

  Future<Stream<BoxEvent>> changes() async => (await _box()).watch();

  Future<void> markRead(String id) async {
    final box = await _box();
    final existing = await box.get(id);
    if (existing == null) return;
    await box.put(id, {...existing, 'read': true});
  }

  // ── Permission ───────────────────────────────────────────────────────────

  Future<bool> isPermissionGranted() async {
    if (!pushSupported) return false;
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }


  Future<bool> requestPermissionWithExplainer(BuildContext context) async {
    if (!pushSupported) return false;
    if (await isPermissionGranted()) return true;
    if (!context.mounted) return false;
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _PermissionExplainer(),
    );
    if (proceed != true) return false;
    final settings = await FirebaseMessaging.instance.requestPermission();
    final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!granted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Notifications are off. You can turn them on later in your phone\'s app settings.'),
      ));
    }
    return granted;
  }

  /// Asks once per install, after the user has landed on Home.
  Future<void> maybeAskOnce() async {
    if (!pushSupported) return;
    try {
      final prefs = await Hive.openBox(FirstRunService.boxName);
      if (prefs.get(_promptShownKey) == true) return;
      if (await isPermissionGranted()) return;
      final context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      await prefs.put(_promptShownKey, true);
      if (!context.mounted) return;
      await requestPermissionWithExplainer(context);
    } catch (_) {}
  }
}

class _PermissionExplainer extends StatelessWidget {
  const _PermissionExplainer();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.cyan.withValues(alpha: 0.15),
                border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.notifications_active_outlined,
                  color: AppTheme.cyan, size: 32),
            ),
            const SizedBox(height: 16),
            Text('Stay in the loop',
                style: AppTheme.orbitron(size: 15, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Get announcements about new lore, conventions and official merch drops. '
              'We only send occasional updates — no spam.',
              textAlign: TextAlign.center,
              style: AppTheme.inter(size: 12, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cyan,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('TURN ON NOTIFICATIONS',
                    style: AppTheme.orbitron(
                        size: 11, color: Colors.black, weight: FontWeight.w800)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Not now',
                  style: AppTheme.inter(size: 12, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
