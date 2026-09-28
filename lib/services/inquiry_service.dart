import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'firestore_db.dart';

enum InquiryResult { sent, queuedOffline }

/// Contact Us submissions, stored in the `inquiries` collection (admins read
/// them in the Firebase console; anyone, including guests, can create one).
class InquiryService {
  static final InquiryService instance = InquiryService._();
  InquiryService._();

  static const Duration _serverWait = Duration(seconds: 12);

  /// Returns [InquiryResult.queuedOffline] if the server didn't confirm in
  /// time: Firestore keeps the write queued on the device and sends it when
  /// the connection returns, so the user shouldn't send it again.
  Future<InquiryResult> submit({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    final write = FirestoreDb.instance.collection('inquiries').add({
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
      'uid': AuthService.instance.currentUser?.uid,
      'status': 'new',
      'createdAt': FieldValue.serverTimestamp(),
    });
    try {
      await write.timeout(_serverWait);
      return InquiryResult.sent;
    } on TimeoutException {
      return InquiryResult.queuedOffline;
    }
  }
}
