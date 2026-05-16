import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String attId;
  final String eventId;
  final String userId;
  final DateTime scannedAt;
  final String method;

  AttendanceModel({
    required this.attId,
    required this.eventId,
    required this.userId,
    required this.scannedAt,
    required this.method,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      attId: doc.id,
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      scannedAt: data['scannedAt'] is Timestamp
          ? (data['scannedAt'] as Timestamp).toDate()
          : DateTime.now(),
      method: data['method'] ?? 'qr',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'scannedAt': Timestamp.fromDate(scannedAt),
      'method': method,
    };
  }
}
