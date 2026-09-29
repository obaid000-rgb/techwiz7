import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/creator.dart';
import 'firestore_db.dart';

class CreatorException implements Exception {
  final String message;
  const CreatorException(this.message);

  @override
  String toString() => message;
}

class CreatorService {
  static final CreatorService instance = CreatorService._();
  CreatorService._();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirestoreDb.instance.collection('creators');

  List<Creator> _sorted(QuerySnapshot<Map<String, dynamic>> s) => s.docs
      .map((d) => Creator.fromMap(d.data(), d.id))
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  Stream<List<Creator>> watchAll() => _col.snapshots().map(_sorted);

  Future<List<Creator>> getAll() async => _sorted(await _col.get());

  Future<List<Creator>> getAllActive() async =>
      (await getAll()).where((c) => c.isActive).toList();


  Stream<Creator?> watchById(String id) => _col.doc(id).snapshots().map((d) {
        final data = d.data();
        return data == null ? null : Creator.fromMap(data, d.id);
      });

  /// Every creator, live.
  Stream<List<Creator>> watchActive() =>
      _col.snapshots().map((s) => _sorted(s).where((c) => c.isActive).toList());

  Future<Creator?> getById(String id) async {
    final doc = await _col.doc(id).get();
    final data = doc.data();
    return data == null ? null : Creator.fromMap(data, doc.id);
  }

  Future<bool> nameExists(String name, {String? excludeId}) async {
    final normalized = name.trim().toLowerCase();
    final s = await _col.get();
    return s.docs.any((d) =>
        d.id != excludeId &&
        (d.data()['name'] as String? ?? '').trim().toLowerCase() == normalized);
  }

  Future<String> create(Creator creator) async {
    final name = creator.name.trim();
    final id = Creator.slugFor(name);
    if (id.isEmpty) {
      throw const CreatorException('The name must contain letters or numbers.');
    }
    if (await nameExists(name)) {
      throw CreatorException('A creator named "$name" already exists.');
    }
    final created = await FirestoreDb.instance.runTransaction((tx) async {
      final ref = _col.doc(id);
      if ((await tx.get(ref)).exists) return false;
      tx.set(ref, {
        ...creator.copyWith(name: name).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (!created) {
      throw CreatorException(
          'A creator with the ID "$id" already exists. Choose a different name.');
    }
    return id;
  }

  Future<void> update(Creator creator) async {
    final name = creator.name.trim();
    if (name.isEmpty) throw const CreatorException('Name is required.');
    if (await nameExists(name, excludeId: creator.id)) {
      throw CreatorException('A creator named "$name" already exists.');
    }
    final before = await getById(creator.id);
    final db = FirestoreDb.instance;
    final batch = db.batch();
    batch.update(_col.doc(creator.id),
        creator.copyWith(name: name).toMap()..remove('createdAt'));
    if (before != null && before.name != name) {
      final posts = await db
          .collection('posts')
          .where('creatorId', isEqualTo: creator.id)
          .get();
      for (final p in posts.docs) {
        batch.update(p.reference, {'creatorName': name});
      }
    }
    await batch.commit();
  }

  Future<void> softDelete(String id) =>
      _col.doc(id).update({'isActive': false});

  Future<void> restore(String id) => _col.doc(id).update({'isActive': true});
}
