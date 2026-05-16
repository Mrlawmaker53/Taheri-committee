import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleModel {
  final String id;
  final String eventId;
  final String name;
  final String type; // Land Cruiser, Eeco, Tempo Traveller
  final int totalSeats;
  final int bookedSeats;
  final int availableSeats;
  final DateTime departureTime;
  final String? route;
  final String? driverName;
  final String? driverMobile;
  final String status; // active, inactive, full
  final String createdBy;
  final DateTime createdAt;

  VehicleModel({
    required this.id,
    required this.eventId,
    required this.name,
    required this.type,
    required this.totalSeats,
    required this.bookedSeats,
    required this.availableSeats,
    required this.departureTime,
    this.route,
    this.driverName,
    this.driverMobile,
    required this.status,
    required this.createdBy,
    required this.createdAt,
  });

  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? 'Land Cruiser',
      totalSeats: data['totalSeats'] ?? 0,
      bookedSeats: data['bookedSeats'] ?? 0,
      availableSeats: data['availableSeats'] ?? 0,
      departureTime: data['departureTime'] is Timestamp
          ? (data['departureTime'] as Timestamp).toDate()
          : DateTime.now(),
      route: data['route'],
      driverName: data['driverName'],
      driverMobile: data['driverMobile'],
      status: data['status'] ?? 'active',
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'name': name,
      'type': type,
      'totalSeats': totalSeats,
      'bookedSeats': bookedSeats,
      'availableSeats': availableSeats,
      'departureTime': Timestamp.fromDate(departureTime),
      'route': route,
      'driverName': driverName,
      'driverMobile': driverMobile,
      'status': status,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get hasSeats => availableSeats > 0 && status == 'active';
  double get occupancyRate =>
      totalSeats > 0 ? (bookedSeats / totalSeats) * 100 : 0;

  /// Default seat counts per vehicle type
  static int defaultSeatsForType(String type) {
    switch (type) {
      case 'Land Cruiser':
        return 11;
      case 'Eeco':
        return 7;
      case 'Tempo Traveller':
        return 15;
      default:
        return 11;
    }
  }

  static const List<String> vehicleTypes = [
    'Land Cruiser',
    'Eeco',
    'Tempo Traveller',
  ];
}
