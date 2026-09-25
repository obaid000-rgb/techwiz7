import '../models/fandom.dart';
import 'firestore_db.dart';

class FandomService {
  static final FandomService instance = FandomService._();
  FandomService._();

  Future<List<Fandom>> fetchFandoms() async {
    final snapshot = await FirestoreDb.instance.collection('fandoms').get();
    return snapshot.docs
        .map((d) => Fandom.fromMap(d.data(), d.id))
        .toList();
  }

  Future<List<Fandom>> fetchByCategory(String category) async {
    final snapshot = await FirestoreDb.instance
        .collection('fandoms')
        .where('category', isEqualTo: category)
        .get();
    return snapshot.docs
        .map((d) => Fandom.fromMap(d.data(), d.id))
        .toList();
  }

  Future<List<Fandom>> fetchByDepth(String depth) async {
    final snapshot = await FirestoreDb.instance
        .collection('fandoms')
        .where('depth', isEqualTo: depth)
        .get();
    return snapshot.docs
        .map((d) => Fandom.fromMap(d.data(), d.id))
        .toList();
  }
}
