import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
// Seat Definition — layout metadata only (no Firestore)
// ─────────────────────────────────────────────
class SeatDefinition {
  final String id;
  final String label;
  final bool isDriver;
  final double x, y, w, h; // logical canvas units

  const SeatDefinition({
    required this.id,
    required this.label,
    this.isDriver = false,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });
}

// ─────────────────────────────────────────────
// Booking Model — mirrors Firestore document
// Path: transport/{transportId}/bookings/{seatId}
// ─────────────────────────────────────────────
class SeatBookingModel {
  final String seatId;
  final String userId;
  final String displayName;
  final String avatarUrl;
  final DateTime bookedAt;

  SeatBookingModel({
    required this.seatId,
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.bookedAt,
  });

  factory SeatBookingModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SeatBookingModel(
      seatId: doc.id,
      userId: d['userId'] ?? '',
      displayName: d['displayName'] ?? '',
      avatarUrl: d['avatarUrl'] ?? '',
      bookedAt: d['bookedAt'] is Timestamp
          ? (d['bookedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'bookedAt': FieldValue.serverTimestamp(),
      };
}

// ─────────────────────────────────────────────
// Vehicle Type enum
// ─────────────────────────────────────────────
enum VehicleType { cruiser, eeco }

extension VehicleTypeX on VehicleType {
  String get label => this == VehicleType.cruiser ? 'Land Cruiser' : 'Eeco';
  int get passengerCount => this == VehicleType.cruiser ? 11 : 6;

  List<SeatDefinition> get layout =>
      this == VehicleType.cruiser ? VehicleLayouts.cruiser : VehicleLayouts.eeco;

  static VehicleType fromString(String? s) =>
      s == 'eeco' ? VehicleType.eeco : VehicleType.cruiser;
}

// ─────────────────────────────────────────────
// Layout definitions
// Cruiser canvas: 240 × 420 logical units
// Row 1 (front): F-L1, F-L2 | DR (RHD)
// Row 2 (mid):   M-L1, M-C1, M-R1  (3 across)
// Row 3-5 (rear): RL-1..3 (left) | RR-1..3 (right) with aisle
// ─────────────────────────────────────────────
class VehicleLayouts {
  static const List<SeatDefinition> cruiser = [
    SeatDefinition(id: 'DR',   label: 'Driver', isDriver: true, x: 148, y: 60,  w: 46, h: 38),
    SeatDefinition(id: 'F-L1', label: 'F-L1',                  x: 50,  y: 60,  w: 46, h: 38),
    SeatDefinition(id: 'F-L2', label: 'F-L2',                  x: 100, y: 60,  w: 46, h: 38),
    SeatDefinition(id: 'M-L1', label: 'M-L1',                  x: 42,  y: 158, w: 46, h: 38),
    SeatDefinition(id: 'M-C1', label: 'M-C1',                  x: 96,  y: 158, w: 46, h: 38),
    SeatDefinition(id: 'M-R1', label: 'M-R1',                  x: 150, y: 158, w: 46, h: 38),
    SeatDefinition(id: 'RL-1', label: 'RL-1',                  x: 50,  y: 240, w: 46, h: 38),
    SeatDefinition(id: 'RR-1', label: 'RR-1',                  x: 144, y: 240, w: 46, h: 38),
    SeatDefinition(id: 'RL-2', label: 'RL-2',                  x: 50,  y: 288, w: 46, h: 38),
    SeatDefinition(id: 'RR-2', label: 'RR-2',                  x: 144, y: 288, w: 46, h: 38),
    SeatDefinition(id: 'RL-3', label: 'RL-3',                  x: 50,  y: 336, w: 46, h: 38),
    SeatDefinition(id: 'RR-3', label: 'RR-3',                  x: 144, y: 336, w: 46, h: 38),
  ];

  // Eeco canvas: 160 × 280 logical units
  static const List<SeatDefinition> eeco = [
    SeatDefinition(id: 'DR',  label: 'Driver', isDriver: true, x: 88,  y: 32,  w: 42, h: 36),
    SeatDefinition(id: 'F-1', label: 'F-1',                   x: 32,  y: 32,  w: 42, h: 36),
    SeatDefinition(id: 'M-1', label: 'M-1',                   x: 32,  y: 90,  w: 42, h: 36),
    SeatDefinition(id: 'M-2', label: 'M-2',                   x: 88,  y: 90,  w: 42, h: 36),
    SeatDefinition(id: 'R-1', label: 'R-1',                   x: 14,  y: 152, w: 42, h: 36),
    SeatDefinition(id: 'R-2', label: 'R-2',                   x: 62,  y: 152, w: 42, h: 36),
    SeatDefinition(id: 'R-3', label: 'R-3',                   x: 110, y: 152, w: 42, h: 36),
  ];
}
