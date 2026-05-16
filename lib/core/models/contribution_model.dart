import 'package:cloud_firestore/cloud_firestore.dart';

class ContributionModel {
  final String id;
  final String memberId;
  final String supervisorId;
  final String teamId;
  final double amount;
  final String note;
  final String status;
  final DateTime raisedAt;
  final DateTime? resolvedAt;
  final String resolvedBy;
  final String receiptNote;

  ContributionModel({
    required this.id,
    required this.memberId,
    required this.supervisorId,
    required this.teamId,
    required this.amount,
    required this.note,
    required this.status,
    required this.raisedAt,
    this.resolvedAt,
    required this.resolvedBy,
    required this.receiptNote,
  });

  factory ContributionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContributionModel(
      id: doc.id,
      memberId: data['memberId'] ?? '',
      supervisorId: data['supervisorId'] ?? '',
      teamId: data['teamId'] ?? '',
      amount: (data['amount'] is int)
          ? (data['amount'] as int).toDouble()
          : (data['amount'] ?? 0.0) as double,
      note: data['note'] ?? '',
      status: data['status'] ?? 'pending',
      raisedAt: data['raisedAt'] is Timestamp
          ? (data['raisedAt'] as Timestamp).toDate()
          : DateTime.now(),
      resolvedAt: data['resolvedAt'] is Timestamp
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      resolvedBy: data['resolvedBy'] ?? '',
      receiptNote: data['receiptNote'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'supervisorId': supervisorId,
      'teamId': teamId,
      'amount': amount,
      'note': note,
      'status': status,
      'raisedAt': Timestamp.fromDate(raisedAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
      'receiptNote': receiptNote,
    };
  }
}
