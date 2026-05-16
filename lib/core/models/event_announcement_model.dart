import 'package:cloud_firestore/cloud_firestore.dart';

class EventAnnouncementModel {
  final String id;
  final String title;
  final String description;
  final String eventId;
  final String eventTitle;
  final DateTime eventDate;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime? deadlineAt;
  final bool isActive;
  final List<String> targetGroups; // Empty means all groups
  final Map<String, AttendanceResponse> responses; // userId -> response

  EventAnnouncementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.deadlineAt,
    this.isActive = true,
    this.targetGroups = const [],
    this.responses = const {},
  });

  factory EventAnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final responsesMap = <String, AttendanceResponse>{};
    
    if (data['responses'] != null) {
      final responses = data['responses'] as Map<String, dynamic>;
      for (final entry in responses.entries) {
        responsesMap[entry.key] = AttendanceResponse.fromMap(entry.value);
      }
    }

    return EventAnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      eventId: data['eventId'] ?? '',
      eventTitle: data['eventTitle'] ?? '',
      eventDate: data['eventDate'] is Timestamp
          ? (data['eventDate'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      deadlineAt: data['deadlineAt'] is Timestamp
          ? (data['deadlineAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      targetGroups: List<String>.from(data['targetGroups'] ?? []),
      responses: responsesMap,
    );
  }

  Map<String, dynamic> toMap() {
    final responsesMap = <String, dynamic>{};
    for (final entry in responses.entries) {
      responsesMap[entry.key] = entry.value.toMap();
    }

    return {
      'title': title,
      'description': description,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'eventDate': Timestamp.fromDate(eventDate),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'deadlineAt': deadlineAt != null ? Timestamp.fromDate(deadlineAt!) : null,
      'isActive': isActive,
      'targetGroups': targetGroups,
      'responses': responsesMap,
    };
  }

  int get yesCount => responses.values.where((r) => r.response == 'yes').length;
  int get noCount => responses.values.where((r) => r.response == 'no').length;
  int get pendingCount => responses.values.where((r) => r.response == 'pending').length;
  int get totalResponses => responses.length;
}

class AttendanceResponse {
  final String response; // 'yes', 'no', 'pending'
  final DateTime respondedAt;
  final String? note;

  AttendanceResponse({
    required this.response,
    required this.respondedAt,
    this.note,
  });

  factory AttendanceResponse.fromMap(Map<String, dynamic> data) {
    return AttendanceResponse(
      response: data['response'] ?? 'pending',
      respondedAt: data['respondedAt'] is Timestamp
          ? (data['respondedAt'] as Timestamp).toDate()
          : DateTime.now(),
      note: data['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'response': response,
      'respondedAt': Timestamp.fromDate(respondedAt),
      'note': note,
    };
  }

  static AttendanceResponse pending() => AttendanceResponse(
    response: 'pending',
    respondedAt: DateTime.now(),
  );
}
