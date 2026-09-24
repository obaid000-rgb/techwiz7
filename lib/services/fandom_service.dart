import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fandom.dart';

class FandomService {
  FandomService._();

  static final _collection = FirebaseFirestore.instance.collection('fandoms').withConverter<Fandom>(
    fromFirestore: (snapshot, _) => Fandom.fromDoc(snapshot),
    toFirestore: (fandom, _) => {
      'name': fandom.name,
      'category': fandom.category,
      'description': fandom.description,
      'trending': fandom.trending,
    },
  );

  static Stream<List<Fandom>> streamFandoms() {
    return _collection.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
    );
  }
}
