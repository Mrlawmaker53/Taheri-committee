import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String eventId;
  final String title;
  final String createdBy;
  final DateTime eventDate;
  final String location;
  final bool rsvpEnabled;
  final bool attendanceEnabled;

  // 🆕 TRANSPORT FIELDS
  final bool transportRequired;
  final int transportCapacity;
  final String transportStatus; // none | planning | active | completed
  final String? transportNotes;
  final DateTime? transportRegistrationDeadline;

  EventModel({
    required this.eventId,
    required this.title,
    required this.createdBy,
    required this.eventDate,
    required this.location,
    required this.rsvpEnabled,
    required this.attendanceEnabled,
    this.transportRequired = false,
    this.transportCapacity = 0,
    this.transportStatus = 'none',
    this.transportNotes,
    this.transportRegistrationDeadline,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      eventId: doc.id,
      title: data['title'] ?? '',
      createdBy: data['createdBy'] ?? '',
      eventDate: data['eventDate'] is Timestamp
          ? (data['eventDate'] as Timestamp).toDate()
          : DateTime.now(),
      location: data['location'] ?? '',
      rsvpEnabled: data['rsvpEnabled'] ?? true,
      attendanceEnabled: data['attendanceEnabled'] ?? true,
      transportRequired: data['transportRequired'] ?? false,
      transportCapacity: data['transportCapacity'] ?? 0,
      transportStatus: data['transportStatus'] ?? 'none',
      transportNotes: data['transportNotes'],
      transportRegistrationDeadline:
          data['transportRegistrationDeadline'] is Timestamp
              ? (data['transportRegistrationDeadline'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'createdBy': createdBy,
      'eventDate': Timestamp.fromDate(eventDate),
      'location': location,
      'rsvpEnabled': rsvpEnabled,
      'attendanceEnabled': attendanceEnabled,
      'transportRequired': transportRequired,
      'transportCapacity': transportCapacity,
      'transportStatus': transportStatus,
      'transportNotes': transportNotes,
      'transportRegistrationDeadline': transportRegistrationDeadline != null
          ? Timestamp.fromDate(transportRegistrationDeadline!)
          : null,
    };
  }
}
