import 'package:cloud_firestore/cloud_firestore.dart';

/// Single access point for the default Firestore database (fandom-verse-pocket-2026).
/// Use `FirestoreDb.instance` everywhere instead of `FirebaseFirestore.instance`.
class FirestoreDb {
  static FirebaseFirestore get instance => FirebaseFirestore.instance;
}
