import 'package:cloud_firestore/cloud_firestore.dart';

class GroupRequestModel {
  final String id;
  final String supervisorId;
  final String leaderId;
  final double totalAmount;
  final List<String> contribIds;
  final String status;
  final DateTime raisedAt;

  GroupRequestModel({
    required this.id,
    required this.supervisorId,
    required this.leaderId,
    required this.totalAmount,
    required this.contribIds,
    required this.status,
    required this.raisedAt,
  });

  factory GroupRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupRequestModel(
      id: doc.id,
      supervisorId: data['supervisorId'] ?? '',
      leaderId: data['leaderId'] ?? '',
      totalAmount: (data['totalAmount'] is int)
          ? (data['totalAmount'] as int).toDouble()
          : (data['totalAmount'] ?? 0.0) as double,
      contribIds: List<String>.from(data['contribIds'] ?? []),
      status: data['status'] ?? 'pending_leader',
      raisedAt: data['raisedAt'] is Timestamp
          ? (data['raisedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'supervisorId': supervisorId,
      'leaderId': leaderId,
      'totalAmount': totalAmount,
      'contribIds': contribIds,
      'status': status,
      'raisedAt': Timestamp.fromDate(raisedAt),
    };
  }
}
