import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String seatId;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final DateTime bookedAt;
  final String status;

  BookingModel({
    required this.seatId,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.bookedAt,
    this.status = 'confirmed',
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return BookingModel(
      seatId: doc.id,
      userId: d['userId'] as String? ?? '',
      displayName: d['displayName'] as String? ?? 'Unknown',
      photoUrl: d['photoUrl'] as String?,
      bookedAt: d['bookedAt'] != null
          ? (d['bookedAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: d['status'] as String? ?? 'confirmed',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'seatId': seatId,
        'userId': userId,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'bookedAt': Timestamp.fromDate(bookedAt),
        'status': status,
      };
}
