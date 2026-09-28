import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/avatar_library_item.dart';
import 'firestore_db.dart';

class AvatarLibraryService {
  static final AvatarLibraryService instance = AvatarLibraryService._();
  AvatarLibraryService._();

  CollectionReference<Map<String, dynamic>> get _col => FirestoreDb.instance.collection('avatarLibrary');

  Stream<List<AvatarLibraryItem>> watchAll() => _col.orderBy('createdAt', descending: true).snapshots().map(
      (s) => s.docs.map((d) => AvatarLibraryItem.fromMap(d.data(), d.id)).toList());

  Stream<List<AvatarLibraryItem>> watchActive() => _col.where('isActive', isEqualTo: true).snapshots().map(
      (s) => s.docs.map((d) => AvatarLibraryItem.fromMap(d.data(), d.id)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Future<void> add(String imageUrl, String categoryId, {bool isActive = true}) => _col.add(AvatarLibraryItem(
        id: '',
        imageUrl: imageUrl,
        categoryId: categoryId,
        isActive: isActive,
        createdAt: DateTime.now(),
      ).toMap());

  Future<void> update(String id, {String? categoryId, bool? isActive}) => _col.doc(id).update({
        'categoryId': ?categoryId,
        'isActive': ?isActive,
      });
}
