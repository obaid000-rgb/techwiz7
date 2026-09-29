import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'firestore_db.dart';

enum InquiryResult { sent, queuedOffline }


class InquiryService {
  static final InquiryService instance = InquiryService._();
  InquiryService._();

  static const Duration _serverWait = Duration(seconds: 12);

  /// Returns [InquiryResult.queuedOffline] if the server didn't confirm in
  /// 
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

  CollectionReference<Map<String, dynamic>> get _col => FirestoreDb.instance.collection('inquiries');

  /// Admin inbox, newest first.
  Stream<List<Inquiry>> watchAll() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Inquiry.fromMap(d.data(), d.id)).toList());

  Future<void> setStatus(String id, String status) => _col.doc(id).update({'status': status});

  Future<void> delete(String id) => _col.doc(id).delete();
}

class Inquiry {
  final String id;
  final String name;
  final String email;
  final String subject;
  final String message;
  final String? uid;
  /// new | read | resolved
  final String status;
  final DateTime? createdAt;

  const Inquiry({
    required this.id,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    this.uid,
    this.status = 'new',
    this.createdAt,
  });

  factory Inquiry.fromMap(Map<String, dynamic> m, String id) => Inquiry(
        id: id,
        name: m['name'] as String? ?? '',
        email: m['email'] as String? ?? '',
        subject: m['subject'] as String? ?? '',
        message: m['message'] as String? ?? '',
        uid: m['uid'] as String?,
        status: m['status'] as String? ?? 'new',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );
}
