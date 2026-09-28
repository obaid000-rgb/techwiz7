import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Kind of fan event. Stored in Firestore as [key]; anything unknown or
/// missing (every event created before types existed) reads as [other].
enum EventType {
  convention('convention', 'Convention', Icons.festival_outlined, AppTheme.pink),
  cosplayMeetup('cosplay_meetup', 'Cosplay Meetup', Icons.theater_comedy_outlined, AppTheme.accent),
  screening('screening', 'Screening', Icons.movie_outlined, AppTheme.cyan),
  tournament('tournament', 'Tournament', Icons.emoji_events_outlined, AppTheme.orange),
  other('other', 'Event', Icons.event_outlined, Colors.blueGrey);

  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const EventType(this.key, this.label, this.icon, this.color);

  static EventType fromKey(String? key) =>
      values.firstWhere((t) => t.key == key, orElse: () => other);
}
