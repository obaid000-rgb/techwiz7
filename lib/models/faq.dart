import 'package:cloud_firestore/cloud_firestore.dart';

class Faq {
  final String id;
  final String question;
  final String answer;
  final int order;
  final bool isActive;
  final DateTime createdAt;

  const Faq({
    required this.id,
    required this.question,
    required this.answer,
    this.order = 0,
    this.isActive = true,
    required this.createdAt,
  });

  factory Faq.fromMap(Map<String, dynamic> map, String id) => Faq(
        id: id,
        question: map['question'] as String? ?? '',
        answer: map['answer'] as String? ?? '',
        order: (map['order'] as num?)?.toInt() ?? 0,
        isActive: map['isActive'] as bool? ?? true,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'question': question,
        'answer': answer,
        'order': order,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
