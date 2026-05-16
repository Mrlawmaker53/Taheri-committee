import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String type;

  // Targeted notification metadata (filled by Cloud Function on send).
  final bool requiresResponse;
  final List<String> responseOptions;
  final String
      notifType; // event_rsvp | announcement | contribution | transfer | broadcast
  final String? eventId;
  final String? announcementId;
  final String? contribId;
  final String? transferId;
  final String sentBy;
  final String sentByName;
  final String targetType; // all | team | role | individual
  final int responseCount;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.type,
    this.requiresResponse = false,
    this.responseOptions = const [],
    this.notifType = 'general',
    this.eventId,
    this.announcementId,
    this.contribId,
    this.transferId,
    this.sentBy = '',
    this.sentByName = '',
    this.targetType = 'all',
    this.responseCount = 0,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      type: data['type'] ?? 'general',
      requiresResponse: data['requiresResponse'] == true,
      responseOptions: (data['responseOptions'] is List)
          ? (data['responseOptions'] as List).map((e) => e.toString()).toList()
          : <String>[],
      notifType: data['notifType']?.toString() ??
          data['type']?.toString() ??
          'general',
      eventId: data['eventId']?.toString(),
      announcementId: data['announcementId']?.toString(),
      contribId: data['contribId']?.toString(),
      transferId: data['transferId']?.toString(),
      sentBy: data['sentBy']?.toString() ?? '',
      sentByName: data['sentByName']?.toString() ?? '',
      targetType: data['targetType']?.toString() ?? 'all',
      responseCount: (data['responseCount'] is num)
          ? (data['responseCount'] as num).toInt()
          : 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type,
      'requiresResponse': requiresResponse,
      'responseOptions': responseOptions,
      'notifType': notifType,
      if (eventId != null) 'eventId': eventId,
      if (announcementId != null) 'announcementId': announcementId,
      if (contribId != null) 'contribId': contribId,
      if (transferId != null) 'transferId': transferId,
      'sentBy': sentBy,
      'sentByName': sentByName,
      'targetType': targetType,
      'responseCount': responseCount,
    };
  }
}

/// One member's response to a `requiresResponse` notification.
class NotificationResponseModel {
  final String responseId;
  final String notificationId;
  final String? eventId;
  final String? announcementId;
  final String userId;
  final String userName;
  final String teamId;
  final String response;
  final DateTime respondedAt;
  final String type; // event_rsvp | announcement_response

  NotificationResponseModel({
    required this.responseId,
    required this.notificationId,
    required this.userId,
    required this.userName,
    required this.teamId,
    required this.response,
    required this.respondedAt,
    required this.type,
    this.eventId,
    this.announcementId,
  });

  factory NotificationResponseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationResponseModel(
      responseId: doc.id,
      notificationId: data['notificationId']?.toString() ?? '',
      eventId: data['eventId']?.toString(),
      announcementId: data['announcementId']?.toString(),
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? '',
      teamId: data['teamId']?.toString() ?? '',
      response: data['response']?.toString() ?? '',
      respondedAt: data['respondedAt'] is Timestamp
          ? (data['respondedAt'] as Timestamp).toDate()
          : DateTime.now(),
      type: data['type']?.toString() ?? 'announcement_response',
    );
  }
}
