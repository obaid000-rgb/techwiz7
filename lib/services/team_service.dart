import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_member.dart';
import 'firestore_db.dart';

/// About Us "Meet the Team", managed by admin in the `teamMembers` collection.
class TeamService {
  static final TeamService instance = TeamService._();
  TeamService._();

  CollectionReference<Map<String, dynamic>> get _col => FirestoreDb.instance.collection('teamMembers');

  Stream<List<TeamMember>> watchAll() => _col.orderBy('order').snapshots().map(
      (s) => s.docs.map((d) => TeamMember.fromMap(d.data(), d.id)).toList());

  /// New members go to the end of the list.
  Future<void> add({required String name, required String role, required String bio, required String imageUrl}) async {
    final last = await _col.orderBy('order', descending: true).limit(1).get();
    final next = last.docs.isEmpty ? 0 : ((last.docs.first.data()['order'] as num?)?.toInt() ?? 0) + 1;
    await _col.add(TeamMember(
      id: '',
      name: name,
      role: role,
      bio: bio,
      imageUrl: imageUrl,
      order: next,
      createdAt: DateTime.now(),
    ).toMap());
  }

  Future<void> update(String id, {required String name, required String role, required String bio, required String imageUrl}) =>
      _col.doc(id).update({'name': name, 'role': role, 'bio': bio, 'imageUrl': imageUrl});

  Future<void> delete(String id) => _col.doc(id).delete();

  Future<void> reorder(List<TeamMember> ordered) async {
    final batch = FirestoreDb.instance.batch();
    for (var i = 0; i < ordered.length; i++) {
      if (ordered[i].order != i) batch.update(_col.doc(ordered[i].id), {'order': i});
    }
    await batch.commit();
  }
}
