import '../models/onboarding_slide.dart';
import 'firestore_db.dart';

class OnboardingSlideService {
  static final OnboardingSlideService instance = OnboardingSlideService._();
  OnboardingSlideService._();

  static const String _collection = 'onboarding_slides';

  Stream<List<OnboardingSlide>> watchSlides() => FirestoreDb.instance
      .collection(_collection)
      .orderBy('order')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => OnboardingSlide.fromMap(d.data(), d.id)).toList());

  Future<List<OnboardingSlide>> fetchSlides() async {
    final s =
        await FirestoreDb.instance.collection(_collection).orderBy('order').get();
    return s.docs.map((d) => OnboardingSlide.fromMap(d.data(), d.id)).toList();
  }

  /// New slides are appended after the current last one.
  Future<void> addSlide(OnboardingSlide slide) async {
    final all = await fetchSlides();
    final nextOrder = all.isEmpty
        ? 0
        : all.map((s) => s.order).reduce((a, b) => a > b ? a : b) + 1;
    await FirestoreDb.instance
        .collection(_collection)
        .add(slide.copyWith(order: nextOrder).toMap());
  }

  Future<void> updateSlide(OnboardingSlide slide) => FirestoreDb.instance
      .collection(_collection)
      .doc(slide.id)
      .update(slide.toMap());

  Future<void> deleteSlide(String id) =>
      FirestoreDb.instance.collection(_collection).doc(id).delete();

  /// Persists a new display order for a full, freshly-ordered list of slides
  /// (index in the list becomes its `order` value).
  Future<void> reorderSlides(List<OnboardingSlide> orderedSlides) async {
    final batch = FirestoreDb.instance.batch();
    for (var i = 0; i < orderedSlides.length; i++) {
      final slide = orderedSlides[i];
      if (slide.order == i) continue;
      batch.update(
        FirestoreDb.instance.collection(_collection).doc(slide.id),
        {'order': i},
      );
    }
    await batch.commit();
  }
}
