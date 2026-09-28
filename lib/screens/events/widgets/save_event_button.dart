import 'package:flutter/material.dart';
import '../../../models/event_item.dart';
import '../../../services/auth_service.dart';
import '../../../services/event_service.dart';
import '../../../services/saved_event_store.dart';
import '../../../theme/app_theme.dart';
import '../../shop/shop_tab.dart' show showGuestLoginSheet;

final Set<String> _busy = {};

void _setSavedLocally(String eventId, bool saved) {
  final current = AuthService.instance.currentUser;
  if (current == null) return;
  final ids = List<String>.from(current.savedEventIds)..remove(eventId);
  if (saved) ids.add(eventId);
  AuthService.instance.userNotifier.value = current.copyWith(savedEventIds: ids);
}

/// Save to / remove from My Agenda. Guests get the login prompt. The saved
/// state flips straight away; the transaction then updates the account and
/// the interested count, and the offline copy is written (or deleted).
Future<void> toggleSaveEvent(BuildContext context, EventItem event) async {
  final user = AuthService.instance.currentUser;
  if (user == null) {
    showGuestLoginSheet(context, feature: 'My Agenda');
    return;
  }
  if (!_busy.add(event.id)) return;
  final messenger = ScaffoldMessenger.of(context);
  final wasSaved = user.savedEventIds.contains(event.id);
  _setSavedLocally(event.id, !wasSaved);
  try {
    final latest = await EventService.instance.setSaved(user.uid, event.id, !wasSaved);
    if (wasSaved) {
      await SavedEventStore.instance.remove(user.uid, event.id);
    } else {
      await SavedEventStore.instance.put(user.uid, latest ?? event);
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(wasSaved ? 'Removed from My Agenda.' : 'Saved to My Agenda. Available offline.'),
      ));
  } catch (e) {
    debugPrint('Save event failed: $e');
    _setSavedLocally(event.id, wasSaved);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(e is SaveEventException
            ? e.message
            : 'Could not update My Agenda. Check your connection and try again.'),
      ));
  } finally {
    _busy.remove(event.id);
  }
}

/// Bookmark icon on event cards.
class SaveEventIconButton extends StatelessWidget {
  final EventItem event;
  const SaveEventIconButton({super.key, required this.event});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<UserData?>(
        valueListenable: AuthService.instance.userNotifier,
        builder: (context, user, _) {
          final saved = user?.savedEventIds.contains(event.id) ?? false;
          return IconButton(
            tooltip: saved ? 'Remove from My Agenda' : 'Save to My Agenda',
            visualDensity: VisualDensity.compact,
            icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: saved ? AppTheme.pink : AppTheme.textMuted),
            onPressed: () => toggleSaveEvent(context, event),
          );
        },
      );
}

/// Full-width "Save to My Agenda" button on Event Detail.
class SaveEventButton extends StatelessWidget {
  final EventItem event;
  const SaveEventButton({super.key, required this.event});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<UserData?>(
        valueListenable: AuthService.instance.userNotifier,
        builder: (context, user, _) {
          final saved = user?.savedEventIds.contains(event.id) ?? false;
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => toggleSaveEvent(context, event),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: saved ? AppTheme.pink : AppTheme.border),
                backgroundColor: saved ? AppTheme.pink.withValues(alpha: 0.12) : null,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
                  color: saved ? AppTheme.pink : Colors.white70, size: 20),
              label: Text(saved ? 'Saved to My Agenda' : 'Save to My Agenda',
                  style: AppTheme.inter(
                      size: 13, weight: FontWeight.w700, color: saved ? AppTheme.pink : Colors.white)),
            ),
          );
        },
      );
}

/// "12 interested"
String interestedLabel(int n) => '$n interested';

/// Grey note on a saved event that was unpublished or deleted.
class NoLongerListedNote extends StatelessWidget {
  const NoLongerListedNote({super.key});

  @override
  Widget build(BuildContext context) => _Note(
        icon: Icons.info_outline,
        text: 'This event is no longer listed',
        color: AppTheme.orange,
      );
}

/// Small note shown when My Agenda is showing saved copies offline.
class OfflineCopyNote extends StatelessWidget {
  final String text;
  const OfflineCopyNote({super.key, this.text = 'Offline, showing saved copies'});

  @override
  Widget build(BuildContext context) => _Note(icon: Icons.wifi_off, text: text, color: AppTheme.textMuted);
}

class _Note extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Note({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(child: Text(text, style: AppTheme.inter(size: 12, color: color, weight: FontWeight.w600))),
        ]),
      );
}
