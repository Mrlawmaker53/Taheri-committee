import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String teamId;
  final String teamName;
  final String supervisorId;
  final String leaderId;
  final int memberCount;
  final DateTime createdAt;

  TeamModel({
    required this.teamId,
    required this.teamName,
    required this.supervisorId,
    required this.leaderId,
    required this.memberCount,
    required this.createdAt,
  });

  factory TeamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamModel(
      teamId: doc.id,
      teamName: data['teamName'] ?? '',
      supervisorId: data['supervisorId'] ?? '',
      leaderId: data['leaderId'] ?? '',
      memberCount: (data['memberCount'] is String)
          ? int.tryParse(data['memberCount'] ?? '0') ?? 0
          : (data['memberCount'] ?? 0) as int,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory TeamModel.fromMap(Map<String, dynamic> data, String id) {
    return TeamModel(
      teamId: id,
      teamName: data['teamName'] ?? '',
      supervisorId: data['supervisorId'] ?? '',
      leaderId: data['leaderId'] ?? '',
      memberCount: (data['memberCount'] is String)
          ? int.tryParse(data['memberCount'] ?? '0') ?? 0
          : (data['memberCount'] ?? 0) as int,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamName': teamName,
      'supervisorId': supervisorId,
      'leaderId': leaderId,
      'memberCount': memberCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
