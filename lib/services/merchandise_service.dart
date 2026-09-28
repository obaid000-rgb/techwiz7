import '../models/merchandise.dart';
import 'firestore_db.dart';

class MerchandiseService {
  static final MerchandiseService instance = MerchandiseService._();
  MerchandiseService._();

  Stream<List<Merchandise>> watchMerchandise() => FirestoreDb.instance
      .collection('merchandise')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => Merchandise.fromMap(d.data(), d.id)).toList());

  Stream<List<Merchandise>> watchMerchandiseByCategory(String categoryKey) =>
      FirestoreDb.instance
          .collection('merchandise')
          .where('category', isEqualTo: categoryKey)
          .snapshots()
          .map((s) =>
              s.docs.map((d) => Merchandise.fromMap(d.data(), d.id)).toList());

  Stream<List<Merchandise>> watchMerchandiseByFandom(String fandomId) =>
      FirestoreDb.instance
          .collection('merchandise')
          .where('fandomId', isEqualTo: fandomId)
          .snapshots()
          .map((s) => s.docs
              .map((d) => Merchandise.fromMap(d.data(), d.id))
              .toList()
            ..sort((a, b) =>
                a.name.toLowerCase().compareTo(b.name.toLowerCase())));

  Future<void> addMerchandise(Merchandise item) =>
      FirestoreDb.instance.collection('merchandise').add(item.toMap());

  Future<void> updateMerchandise(Merchandise item) => FirestoreDb.instance
      .collection('merchandise')
      .doc(item.id)
      .update(item.toMap());

  Future<void> deleteMerchandise(String id) =>
      FirestoreDb.instance.collection('merchandise').doc(id).delete();
}
