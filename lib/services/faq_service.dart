import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/faq.dart';
import 'firestore_db.dart';

class FaqService {
  static final FaqService instance = FaqService._();
  FaqService._();

  CollectionReference<Map<String, dynamic>> get _col => FirestoreDb.instance.collection('faqs');

  /// Every FAQ (admin), in display order.
  Stream<List<Faq>> watchAll() => _col.orderBy('order').snapshots().map(
      (s) => s.docs.map((d) => Faq.fromMap(d.data(), d.id)).toList());

  /// Active FAQs for Contact Us, in display order. Single where, sorted on
  /// the device, so no composite index is needed.
  Stream<List<Faq>> watchActive() => _col.where('isActive', isEqualTo: true).snapshots().map(
      (s) => s.docs.map((d) => Faq.fromMap(d.data(), d.id)).toList()
        ..sort((a, b) => a.order.compareTo(b.order)));

  Future<List<Faq>> fetchActive() async {
    final s = await _col.where('isActive', isEqualTo: true).get();
    return s.docs.map((d) => Faq.fromMap(d.data(), d.id)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// New FAQs go to the end of the list.
  Future<void> add({required String question, required String answer, bool isActive = true}) async {
    final last = await _col.orderBy('order', descending: true).limit(1).get();
    final next = last.docs.isEmpty ? 0 : ((last.docs.first.data()['order'] as num?)?.toInt() ?? 0) + 1;
    await _col.add(Faq(
      id: '',
      question: question,
      answer: answer,
      order: next,
      isActive: isActive,
      createdAt: DateTime.now(),
    ).toMap());
  }

  Future<void> update(String id, {required String question, required String answer, required bool isActive}) =>
      _col.doc(id).update({'question': question, 'answer': answer, 'isActive': isActive});

  Future<void> delete(String id) => _col.doc(id).delete();

  /// Saves a new order: each FAQ's index in [ordered] becomes its `order`.
  Future<void> reorder(List<Faq> ordered) async {
    final batch = FirestoreDb.instance.batch();
    for (var i = 0; i < ordered.length; i++) {
      if (ordered[i].order != i) batch.update(_col.doc(ordered[i].id), {'order': i});
    }
    await batch.commit();
  }
}
