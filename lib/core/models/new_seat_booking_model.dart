import 'package:cloud_firestore/cloud_firestore.dart';

/// Top-level /seatBookings/{bookingId} document model.
/// This replaces the subcollection-based booking model.
class NewSeatBookingModel {
  final String id;
  final String eventId;
  final String vehicleId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? userMobile;
  final String teamId;
  final String teamName;
  final int? seatNumber;
  final String bookingCode;
  final String status; // confirmed, cancelled
  final DateTime bookedAt;
  final DateTime? cancelledAt;
  final String qrCode;

  NewSeatBookingModel({
    required this.id,
    required this.eventId,
    required this.vehicleId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.userMobile,
    required this.teamId,
    required this.teamName,
    this.seatNumber,
    required this.bookingCode,
    required this.status,
    required this.bookedAt,
    this.cancelledAt,
    required this.qrCode,
  });

  factory NewSeatBookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NewSeatBookingModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      vehicleId: data['vehicleId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatar: data['userAvatar'],
      userMobile: data['userMobile'],
      teamId: data['teamId'] ?? '',
      teamName: data['teamName'] ?? '',
      seatNumber: data['seatNumber'],
      bookingCode: data['bookingCode'] ?? '',
      status: data['status'] ?? 'confirmed',
      bookedAt: data['bookedAt'] is Timestamp
          ? (data['bookedAt'] as Timestamp).toDate()
          : DateTime.now(),
      cancelledAt: data['cancelledAt'] is Timestamp
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      qrCode: data['qrCode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'vehicleId': vehicleId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'userMobile': userMobile,
      'teamId': teamId,
      'teamName': teamName,
      'seatNumber': seatNumber,
      'bookingCode': bookingCode,
      'status': status,
      'bookedAt': Timestamp.fromDate(bookedAt),
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'qrCode': qrCode,
    };
  }

  bool get isActive => status == 'confirmed';
}
