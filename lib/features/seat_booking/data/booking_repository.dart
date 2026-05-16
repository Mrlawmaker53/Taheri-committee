import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/booking_model.dart';

class BookingRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  /// Live stream of all bookings for an event: seatId → BookingModel
  Stream<Map<String, BookingModel>> watchBookings(String eventId) {
    return _db.collection('events/$eventId/bookings').snapshots().map((snap) =>
        {for (final doc in snap.docs) doc.id: BookingModel.fromFirestore(doc)});
  }

  /// Returns this user's booked seatId for the event, or null
  Future<String?> getUserBookedSeat(String eventId) async {
    final query = await _db
        .collection('events/$eventId/bookings')
        .where('userId', isEqualTo: _uid)
        .limit(1)
        .get();
    return query.docs.isEmpty ? null : query.docs.first.id;
  }

  /// Atomic booking: fails if seat taken OR user already has a seat
  Future<void> bookSeat({
    required String eventId,
    required String seatId,
  }) async {
    if (_auth.currentUser == null) throw Exception('Not logged in');

    // 1. Check if user already has a booking (client-side pre-check)
    final existing = await getUserBookedSeat(eventId);
    if (existing != null) {
      throw Exception('You already have seat $existing. Release it first.');
    }

    // 2. Get user info for the booking document
    final userSnap = await _db.doc('users/$_uid').get();
    if (!userSnap.exists) throw Exception('User profile not found');
    final userData = userSnap.data()!;
    final displayName = userData['fullName'] as String? ?? 'Unknown';
    final photoUrl = userData['avatarUrl'] as String?;

    // 3. Atomic transaction — will fail if seat doc already exists
    final seatRef = _db.doc('events/$eventId/bookings/$seatId');
    final eventRef = _db.doc('events/$eventId');

    try {
      await _db.runTransaction((txn) async {
        final seatSnap = await txn.get(seatRef);
        if (seatSnap.exists) {
          throw Exception('Seat $seatId was just taken — pick another.');
        }
        txn.set(seatRef, {
          'seatId': seatId,
          'userId': _uid,
          'displayName': displayName,
          'photoUrl': photoUrl,
          'bookedAt': FieldValue.serverTimestamp(),
          'status': 'confirmed',
        });
      });
    } on FirebaseException catch (e) {
      throw Exception('Booking failed: ${e.message}');
    }

    // 4. Update event status if now full
    await _updateEventStatus(eventId, eventRef);
  }

  /// Release own seat
  Future<void> releaseSeat({
    required String eventId,
    required String seatId,
  }) async {
    final seatRef = _db.doc('events/$eventId/bookings/$seatId');
    final snap = await seatRef.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    if (data['userId'] != _uid) {
      throw Exception('You cannot release another member\'s seat.');
    }
    await seatRef.delete();
    await _updateEventStatus(eventId, _db.doc('events/$eventId'));
  }

  Future<void> _updateEventStatus(
      String eventId, DocumentReference eventRef) async {
    final eventSnap = await eventRef.get();
    final totalSeats = (eventSnap.data() as Map)['totalSeats'] as int;
    final bookingsCount =
        (await _db.collection('events/$eventId/bookings').count().get())
                .count ??
            0;
    final newStatus = bookingsCount >= totalSeats ? 'full' : 'open';
    await eventRef.update({'status': newStatus});
  }

  // ─── Admin only ───────────────────────────────────────────────────────────

  Future<void> adminReleaseSeat({
    required String eventId,
    required String seatId,
  }) async {
    await _db.doc('events/$eventId/bookings/$seatId').delete();
    await _updateEventStatus(eventId, _db.doc('events/$eventId'));
  }

  Future<List<BookingModel>> getAllBookings(String eventId) async {
    final snap = await _db
        .collection('events/$eventId/bookings')
        .orderBy('bookedAt')
        .get();
    return snap.docs.map(BookingModel.fromFirestore).toList();
  }

  Future<String> exportCsv(String eventId) async {
    final bookings = await getAllBookings(eventId);
    final rows = ['Seat ID,Member Name,Booked At'];
    for (final b in bookings) {
      rows.add('${b.seatId},${b.displayName},${b.bookedAt.toIso8601String()}');
    }
    return rows.join('\n');
  }
}
