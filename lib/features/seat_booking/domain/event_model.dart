import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String departureTime;
  final String departureLocation;
  final String destination;
  final String vehicleType;     // "cruiser" | "eeco"
  final int totalSeats;
  final String status;          // "draft"|"open"|"full"|"completed"
  final String createdBy;
  final String? imageUrl;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.departureTime,
    required this.departureLocation,
    required this.destination,
    required this.vehicleType,
    required this.totalSeats,
    required this.status,
    required this.createdBy,
    this.imageUrl,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: d['title'] as String,
      description: d['description'] as String? ?? '',
      date: (d['date'] as Timestamp).toDate(),
      departureTime: d['departureTime'] as String,
      departureLocation: d['departureLocation'] as String,
      destination: d['destination'] as String,
      vehicleType: d['vehicleType'] as String,
      totalSeats: d['totalSeats'] as int,
      status: d['status'] as String,
      createdBy: d['createdBy'] as String,
      imageUrl: d['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'description': description,
    'date': Timestamp.fromDate(date),
    'departureTime': departureTime,
    'departureLocation': departureLocation,
    'destination': destination,
    'vehicleType': vehicleType,
    'totalSeats': totalSeats,
    'status': status,
    'createdBy': createdBy,
    'imageUrl': imageUrl,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
