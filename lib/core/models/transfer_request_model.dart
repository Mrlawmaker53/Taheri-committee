import 'package:cloud_firestore/cloud_firestore.dart';

class TransferRequestModel {
  final String id;
  final String memberId;
  final String fromTeamId;
  final String toTeamId;
  final String requestedBy;
  final String reason;
  final String status;
  final DateTime createdAt;
  final String supervisorNote;
  final String leaderNote;

  TransferRequestModel({
    required this.id,
    required this.memberId,
    required this.fromTeamId,
    required this.toTeamId,
    required this.requestedBy,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.supervisorNote,
    required this.leaderNote,
  });

  factory TransferRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransferRequestModel(
      id: doc.id,
      memberId: data['memberId'] ?? '',
      fromTeamId: data['fromTeamId'] ?? '',
      toTeamId: data['toTeamId'] ?? '',
      requestedBy: data['requestedBy'] ?? '',
      reason: data['reason'] ?? '',
      status: data['status'] ?? 'pending_supervisor',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      supervisorNote: data['supervisorNote'] ?? '',
      leaderNote: data['leaderNote'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'fromTeamId': fromTeamId,
      'toTeamId': toTeamId,
      'requestedBy': requestedBy,
      'reason': reason,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'supervisorNote': supervisorNote,
      'leaderNote': leaderNote,
    };
  }
}
