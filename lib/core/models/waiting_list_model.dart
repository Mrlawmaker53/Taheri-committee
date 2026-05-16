import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
// Waiting List Model - for transport seat overflow
// Path: transport/{transportId}/waitingList/{userId}
// ─────────────────────────────────────────────
class WaitingListModel {
  final String userId;
  final String displayName;
  final String eventId;
  final String transportId;
  final DateTime requestedAt;
  final String priority; // member | volunteer | elder | priority
  final String? contactNumber;
  final String status; // waiting | notified | seated | cancelled

  WaitingListModel({
    required this.userId,
    required this.displayName,
    required this.eventId,
    required this.transportId,
    required this.requestedAt,
    this.priority = 'member',
    this.contactNumber,
    this.status = 'waiting',
  });

  factory WaitingListModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WaitingListModel(
      userId: doc.id,
      displayName: data['displayName'] ?? '',
      eventId: data['eventId'] ?? '',
      transportId: data['transportId'] ?? '',
      requestedAt: data['requestedAt'] is Timestamp
          ? (data['requestedAt'] as Timestamp).toDate()
          : DateTime.now(),
      priority: data['priority'] ?? 'member',
      contactNumber: data['contactNumber'],
      status: data['status'] ?? 'waiting',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'eventId': eventId,
      'transportId': transportId,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'priority': priority,
      'contactNumber': contactNumber,
      'status': status,
    };
  }

  // Priority levels for ordering
  static int getPriorityValue(String priority) {
    switch (priority) {
      case 'elder':
        return 1;
      case 'priority':
        return 2;
      case 'volunteer':
        return 3;
      case 'member':
        return 4;
      default:
        return 5;
    }
  }

  // Status colors for UI
  static String getStatusColor(String status) {
    switch (status) {
      case 'waiting':
        return '#FF9800'; // Orange
      case 'notified':
        return '#2196F3'; // Blue
      case 'seated':
        return '#4CAF50'; // Green
      case 'cancelled':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }
}
