import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogModel {
  final String logId;
  final String actorId;
  final String actorName;
  final String actorRole;
  final String action;
  final String targetId;
  final String targetType;
  final String targetName;
  final String note;
  final DateTime timestamp;

  ActivityLogModel({
    required this.logId,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.targetId,
    required this.targetType,
    required this.targetName,
    required this.note,
    required this.timestamp,
  });

  factory ActivityLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityLogModel(
      logId: doc.id,
      actorId: data['actorId'] ?? '',
      actorName: data['actorName'] ?? '',
      actorRole: data['actorRole'] ?? '',
      action: data['action'] ?? '',
      targetId: data['targetId'] ?? '',
      targetType: data['targetType'] ?? '',
      targetName: data['targetName'] ?? '',
      note: data['note'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  String get actionLabel {
    const labels = {
      'contribution_raised': 'Contribution Raised',
      'contribution_approved': 'Contribution Approved',
      'contribution_declined': 'Contribution Declined',
      'group_request_raised': 'Group Request Raised',
      'group_request_approved': 'Group Request Approved',
      'group_request_declined': 'Group Request Declined',
      'transfer_raised': 'Transfer Request Raised',
      'transfer_supervisor_approved': 'Transfer Approved by Supervisor',
      'transfer_supervisor_declined': 'Transfer Declined by Supervisor',
      'transfer_leader_approved': 'Transfer Approved by Leader',
      'transfer_leader_declined': 'Transfer Declined by Leader',
      'member_role_changed': 'Member Role Changed',
      'member_team_moved': 'Member Moved to Team',
      'event_created': 'Event Created',
      'attendance_marked': 'Attendance Marked',
      'announcement_published': 'Announcement Published',
    };
    return labels[action] ?? action;
  }

  Map<String, dynamic> toMap() {
    return {
      'actorId': actorId,
      'actorName': actorName,
      'actorRole': actorRole,
      'action': action,
      'targetId': targetId,
      'targetType': targetType,
      'targetName': targetName,
      'note': note,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
