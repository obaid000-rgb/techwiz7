import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'auth_service.dart';
import 'firestore_db.dart';

class BackupRecord {
  final String id;
  final DateTime exportedAt;
  final String adminEmail;
  final Map<String, int> counts;
  final int fileSizeBytes;
  final List<String> warnings;

  const BackupRecord({
    required this.id,
    required this.exportedAt,
    required this.adminEmail,
    required this.counts,
    required this.fileSizeBytes,
    this.warnings = const [],
  });

  factory BackupRecord.fromMap(Map<String, dynamic> m, String id) => BackupRecord(
        id: id,
        exportedAt: (m['exportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        adminEmail: m['adminEmail'] as String? ?? '',
        counts: {
          for (final e in ((m['counts'] as Map?) ?? const {}).entries)
            '${e.key}': (e.value as num?)?.toInt() ?? 0,
        },
        fileSizeBytes: (m['fileSizeBytes'] as num?)?.toInt() ?? 0,
        warnings: (m['warnings'] as List?)?.whereType<String>().toList() ?? const [],
      );

  int get totalDocs => counts.values.fold(0, (a, b) => a + b);
}

class BackupResult {
  final String fileName;
  final int fileSizeBytes;
  final Map<String, int> counts;
  final List<String> warnings;
  const BackupResult(this.fileName, this.fileSizeBytes, this.counts, this.warnings);
}

/// Admin "Backup & Export": every Firestore collection the app uses, as one
/// JSON file the admin shares to Drive, Files or email. No paid services.
class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  static const appVersion = '1.0.0+1';

  /// Every top-level collection the app reads or writes.
  static const topLevelCollections = [
    'users',
    'categories',
    'fandoms',
    'posts',
    'creators',
    'merchandise',
    'events',
    'glossary',
    'faqs',
    'teamMembers',
    'onboarding_slides',
    'avatarLibrary',
    'orders',
    'inquiries',
  ];

  /// Subcollections, exported with collectionGroup (key = label in the file).
  static const subcollections = {'users/*/cart': 'cart'};

  CollectionReference<Map<String, dynamic>> get _backups =>
      FirestoreDb.instance.collection('backups');

  Stream<List<BackupRecord>> watchHistory() => _backups
      .orderBy('exportedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => BackupRecord.fromMap(d.data(), d.id)).toList());

  /// The newest backup, or null if there has never been one.
  Stream<BackupRecord?> watchLatest() => _backups
      .orderBy('exportedAt', descending: true)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : BackupRecord.fromMap(s.docs.first.data(), s.docs.first.id));

  /// Converts Firestore values to plain JSON:
  ///  - Timestamp -> ISO-8601 string in UTC ("2026-09-28T10:15:00.000Z"), so
  ///    the file is readable anywhere and sorts correctly as text;
  ///  - GeoPoint -> { "lat": .., "lng": .. };
  ///  - DocumentReference -> its path; Blob -> base64;
  ///  - maps and lists are converted recursively.
  static Object? toJsonValue(Object? v) {
    if (v is Timestamp) return v.toDate().toUtc().toIso8601String();
    if (v is DateTime) return v.toUtc().toIso8601String();
    if (v is GeoPoint) return {'lat': v.latitude, 'lng': v.longitude};
    if (v is DocumentReference) return v.path;
    if (v is Blob) return base64Encode(v.bytes);
    if (v is Map) return {for (final e in v.entries) '${e.key}': toJsonValue(e.value)};
    if (v is List) return [for (final x in v) toJsonValue(x)];
    if (v is num || v is String || v is bool || v == null) return v;
    return '$v';
  }

  static String fileNameFor(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'fandom_verse_backup_${t.year}-${two(t.month)}-${two(t.day)}_${two(t.hour)}${two(t.minute)}.json';
  }

  /// Reads everything, writes the JSON file, opens the share sheet and
  /// records the backup. A collection that can't be read is listed in
  /// warnings instead of failing the whole export.
  Future<BackupResult> exportAll() async {
    final db = FirestoreDb.instance;
    final now = DateTime.now();
    final data = <String, Object?>{};
    final counts = <String, int>{};
    final warnings = <String>[];

    Future<void> read(String label, Future<QuerySnapshot<Map<String, dynamic>>> Function() load,
        {bool fullPath = false}) async {
      try {
        final snap = await load();
        data[label] = {
          for (final d in snap.docs) (fullPath ? d.reference.path : d.id): toJsonValue(d.data()),
        };
        counts[label] = snap.docs.length;
      } catch (e) {
        debugPrint('Backup: could not read $label: $e');
        warnings.add('$label: could not be read ($e)');
      }
    }

    for (final c in topLevelCollections) {
      await read(c, () => db.collection(c).get());
    }
    for (final e in subcollections.entries) {
      await read(e.key, () => db.collectionGroup(e.value).get(), fullPath: true);
    }

    final adminEmail = AuthService.instance.currentUser?.email ?? '';
    final json = const JsonEncoder.withIndent('  ').convert({
      'exportedAt': now.toUtc().toIso8601String(),
      'exportedBy': adminEmail,
      'appVersion': appVersion,
      'counts': counts,
      if (warnings.isNotEmpty) 'warnings': warnings,
      'note': 'Firebase Auth accounts are not included.',
      'data': data,
    });
    final bytes = utf8.encode(json);
    final fileName = fileNameFor(now);

    final XFile file;
    if (kIsWeb) {
      file = XFile.fromData(bytes, name: fileName, mimeType: 'application/json');
    } else {
      // The app documents folder: the one Hive already stores its files in.
      final prefs = await Hive.openBox('app_prefs');
      final dir = File(prefs.path!).parent.path;
      final path = '$dir${Platform.pathSeparator}$fileName';
      await File(path).writeAsBytes(bytes, flush: true);
      file = XFile(path, mimeType: 'application/json', name: fileName);
    }

    await _backups.add({
      'exportedAt': Timestamp.fromDate(now),
      'adminEmail': adminEmail,
      'counts': counts,
      'fileSizeBytes': bytes.length,
      'fileName': fileName,
      if (warnings.isNotEmpty) 'warnings': warnings,
    });

    await SharePlus.instance.share(ShareParams(
      files: [file],
      subject: 'Fandom Verse backup ${fileName.substring(20, 35)}',
      fileNameOverrides: [fileName],
    ));

    return BackupResult(fileName, bytes.length, counts, warnings);
  }
}
