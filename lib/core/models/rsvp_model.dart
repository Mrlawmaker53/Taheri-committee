import 'package:cloud_firestore/cloud_firestore.dart';

class RsvpModel {
  final String rsvpId;
  final String eventId;
  final String userId;
  final String status;
  final bool needsTransport;
  final DateTime respondedAt;

  RsvpModel({
    required this.rsvpId,
    required this.eventId,
    required this.userId,
    required this.status,
    this.needsTransport = false,
    required this.respondedAt,
  });

  factory RsvpModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RsvpModel(
      rsvpId: doc.id,
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      status: data['status'] ?? 'pending',
      needsTransport: data['needsTransport'] ?? false,
      respondedAt: data['respondedAt'] is Timestamp
          ? (data['respondedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'status': status,
      'needsTransport': needsTransport,
      'respondedAt': Timestamp.fromDate(respondedAt),
    };
  }
}
