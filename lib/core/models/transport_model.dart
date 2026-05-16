// lib/core/models/transport_model.dart
// UPDATED: added vehicleType and totalSeats fields
// Drop this file in place of the existing transport_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'seat_booking_model.dart';

class TransportModel {
  final String id;
  final String teamId;
  final String vehicleLabel;
  final String driverName;
  final String status;
  final String route;

  /// NEW ─ 'cruiser' | 'eeco'  (defaults to 'cruiser' for legacy docs)
  final VehicleType vehicleType;

  // 🆕 EVENT LINKAGE
  final String eventId;
  final String? eventTitle;

  // 🆕 TRANSPORT MANAGEMENT
  final DateTime? departureTime;
  final DateTime? returnTime;
  final String? pickupPoint;
  final String? contactPerson;
  final String priority; // high | medium | low

  // 🆕 CAPACITY TRACKING
  final int currentBookings;
  final int waitingList;

  // 🆕 METADATA
  final DateTime createdAt;
  final DateTime updatedAt;

  TransportModel({
    required this.id,
    required this.teamId,
    required this.vehicleLabel,
    required this.driverName,
    required this.status,
    required this.route,
    required this.eventId, // 🆕 Required for event linkage
    this.vehicleType = VehicleType.cruiser,
    this.eventTitle,
    this.departureTime,
    this.returnTime,
    this.pickupPoint,
    this.contactPerson,
    this.priority = 'medium',
    this.currentBookings = 0,
    this.waitingList = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalSeats => vehicleType.passengerCount;

  factory TransportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransportModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      vehicleLabel: data['vehicleLabel'] ?? '',
      driverName: data['driverName'] ?? '',
      status: data['status'] ?? 'active',
      route: data['route'] ?? '',
      eventId:
          data['eventId'] ?? '', // 🆕 Required for new docs, empty for legacy
      eventTitle: data['eventTitle'],
      vehicleType: data['vehicleType'] == 'eeco'
          ? VehicleType.eeco
          : VehicleType.cruiser,
      departureTime: data['departureTime'] is Timestamp
          ? (data['departureTime'] as Timestamp).toDate()
          : null,
      returnTime: data['returnTime'] is Timestamp
          ? (data['returnTime'] as Timestamp).toDate()
          : null,
      pickupPoint: data['pickupPoint'],
      contactPerson: data['contactPerson'],
      priority: data['priority'] ?? 'medium',
      currentBookings: data['currentBookings'] ?? 0,
      waitingList: data['waitingList'] ?? 0,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'vehicleLabel': vehicleLabel,
      'driverName': driverName,
      'status': status,
      'route': route,
      'eventId': eventId, // 🆕 Event linkage
      'eventTitle': eventTitle,
      'vehicleType': vehicleType == VehicleType.eeco ? 'eeco' : 'cruiser',
      'departureTime':
          departureTime != null ? Timestamp.fromDate(departureTime!) : null,
      'returnTime': returnTime != null ? Timestamp.fromDate(returnTime!) : null,
      'pickupPoint': pickupPoint,
      'contactPerson': contactPerson,
      'priority': priority,
      'currentBookings': currentBookings,
      'waitingList': waitingList,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
