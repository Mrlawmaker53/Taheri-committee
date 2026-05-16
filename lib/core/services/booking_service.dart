import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/new_seat_booking_model.dart';
import '../models/vehicle_model.dart';

/// Result wrapper for service operations.
class BookingResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  BookingResult.success(this.data)
      : error = null,
        isSuccess = true;

  BookingResult.error(this.error)
      : data = null,
        isSuccess = false;
}

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Booking code generator ──────────────────────────────────────────
  String _generateBookingCode(int sequence) {
    final now = DateTime.now();
    final dateStr =
        '${now.year % 100}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'TC$dateStr${sequence.toString().padLeft(4, '0')}';
  }

  // ── Duplicate-booking check ──────────────────────────────────────────
  Future<bool> hasExistingBooking(String eventId, String userId) async {
    final snap = await _firestore
        .collection('seatBookings')
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'confirmed')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ── RSVP check ──────────────────────────────────────────────────────
  Future<bool> hasValidRsvp(String eventId, String userId) async {
    final snap = await _firestore
        .collection('rsvp')
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'attending')
        .where('needsTransport', isEqualTo: true)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ── Book a seat (atomic transaction) ─────────────────────────────────
  Future<BookingResult<NewSeatBookingModel>> bookSeat({
    required String eventId,
    required String vehicleId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return BookingResult.error('Not authenticated');
      }

      // Pre-checks
      final alreadyBooked = await hasExistingBooking(eventId, userId);
      if (alreadyBooked) {
        return BookingResult.error(
            'You have already booked a seat for this event');
      }

      final validRsvp = await hasValidRsvp(eventId, userId);
      if (!validRsvp) {
        return BookingResult.error(
            'Please RSVP "Going" and confirm you need transport first');
      }

      // Atomic transaction
      NewSeatBookingModel? booking;

      await _firestore.runTransaction((txn) async {
        final vehicleRef = _firestore.collection('vehicles').doc(vehicleId);
        final vehicleDoc = await txn.get(vehicleRef);

        if (!vehicleDoc.exists) {
          throw Exception('Vehicle not found');
        }

        final vehicle = VehicleModel.fromFirestore(vehicleDoc);

        if (vehicle.availableSeats <= 0) {
          throw Exception('No seats available in this vehicle');
        }
        if (vehicle.status != 'active') {
          throw Exception('This vehicle is not available for booking');
        }

        // Generate booking
        final sequence = vehicle.bookedSeats + 1;
        final bookingCode = _generateBookingCode(sequence);
        final bookingRef = _firestore.collection('seatBookings').doc();

        booking = NewSeatBookingModel(
          id: bookingRef.id,
          eventId: eventId,
          vehicleId: vehicleId,
          userId: userId,
          userName: userData['displayName'] ?? 'User',
          userAvatar: userData['avatarUrl'],
          userMobile: userData['mobile'],
          teamId: userData['teamId'] ?? '',
          teamName: userData['teamName'] ?? '',
          bookingCode: bookingCode,
          status: 'confirmed',
          bookedAt: DateTime.now(),
          qrCode: bookingCode,
        );

        // Write booking doc
        txn.set(bookingRef, booking!.toMap());

        // Update vehicle counters
        final newBooked = vehicle.bookedSeats + 1;
        final newAvailable = vehicle.totalSeats - newBooked;
        txn.update(vehicleRef, {
          'bookedSeats': newBooked,
          'availableSeats': newAvailable,
          'status': newAvailable == 0 ? 'full' : 'active',
        });
      });

      return BookingResult.success(booking!);
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      return BookingResult.error(msg);
    }
  }

  // ── Cancel booking (atomic) ──────────────────────────────────────────
  Future<BookingResult<void>> cancelBooking(String bookingId) async {
    try {
      await _firestore.runTransaction((txn) async {
        final bookingRef =
            _firestore.collection('seatBookings').doc(bookingId);
        final bookingDoc = await txn.get(bookingRef);

        if (!bookingDoc.exists) {
          throw Exception('Booking not found');
        }

        final booking = NewSeatBookingModel.fromFirestore(bookingDoc);
        if (booking.status != 'confirmed') {
          throw Exception('Booking is already cancelled');
        }

        final vehicleRef =
            _firestore.collection('vehicles').doc(booking.vehicleId);
        final vehicleDoc = await txn.get(vehicleRef);

        if (!vehicleDoc.exists) {
          throw Exception('Vehicle not found');
        }

        final vehicle = VehicleModel.fromFirestore(vehicleDoc);

        // Cancel booking
        txn.update(bookingRef, {
          'status': 'cancelled',
          'cancelledAt': Timestamp.now(),
        });

        // Update vehicle counters
        final newBooked = (vehicle.bookedSeats - 1).clamp(0, vehicle.totalSeats);
        final newAvailable = vehicle.totalSeats - newBooked;
        txn.update(vehicleRef, {
          'bookedSeats': newBooked,
          'availableSeats': newAvailable,
          'status': 'active',
        });
      });

      return BookingResult.success(null);
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      return BookingResult.error(msg);
    }
  }

  // ── Get user's active booking for an event ───────────────────────────
  Future<NewSeatBookingModel?> getUserBooking(
      String eventId, String userId) async {
    final snap = await _firestore
        .collection('seatBookings')
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'confirmed')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return NewSeatBookingModel.fromFirestore(snap.docs.first);
  }

  // ── Streams ──────────────────────────────────────────────────────────

  Stream<List<VehicleModel>> getEventVehicles(String eventId) {
    return _firestore
        .collection('vehicles')
        .where('eventId', isEqualTo: eventId)
        .orderBy('departureTime')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => VehicleModel.fromFirestore(d)).toList());
  }

  Stream<List<NewSeatBookingModel>> getVehicleBookings(String vehicleId) {
    return _firestore
        .collection('seatBookings')
        .where('vehicleId', isEqualTo: vehicleId)
        .where('status', isEqualTo: 'confirmed')
        .orderBy('bookedAt')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => NewSeatBookingModel.fromFirestore(d)).toList());
  }

  Stream<List<NewSeatBookingModel>> getEventBookings(String eventId) {
    return _firestore
        .collection('seatBookings')
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: 'confirmed')
        .orderBy('bookedAt')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => NewSeatBookingModel.fromFirestore(d)).toList());
  }

  // ── Admin: vehicle CRUD ──────────────────────────────────────────────

  Future<BookingResult<VehicleModel>> createVehicle({
    required String eventId,
    required String name,
    required String type,
    required int totalSeats,
    required DateTime departureTime,
    String? route,
    String? driverName,
    String? driverMobile,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return BookingResult.error('Not authenticated');

      final ref = _firestore.collection('vehicles').doc();
      final vehicle = VehicleModel(
        id: ref.id,
        eventId: eventId,
        name: name,
        type: type,
        totalSeats: totalSeats,
        bookedSeats: 0,
        availableSeats: totalSeats,
        departureTime: departureTime,
        route: route,
        driverName: driverName,
        driverMobile: driverMobile,
        status: 'active',
        createdBy: userId,
        createdAt: DateTime.now(),
      );

      await ref.set(vehicle.toMap());
      return BookingResult.success(vehicle);
    } catch (e) {
      return BookingResult.error(e.toString());
    }
  }

  Future<BookingResult<void>> updateVehicle(
      String vehicleId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('vehicles').doc(vehicleId).update(updates);
      return BookingResult.success(null);
    } catch (e) {
      return BookingResult.error(e.toString());
    }
  }

  Future<BookingResult<void>> deleteVehicle(String vehicleId) async {
    try {
      // Check for active bookings
      final bookings = await _firestore
          .collection('seatBookings')
          .where('vehicleId', isEqualTo: vehicleId)
          .where('status', isEqualTo: 'confirmed')
          .limit(1)
          .get();

      if (bookings.docs.isNotEmpty) {
        return BookingResult.error(
            'Cannot delete vehicle with active bookings');
      }

      await _firestore.collection('vehicles').doc(vehicleId).delete();
      return BookingResult.success(null);
    } catch (e) {
      return BookingResult.error(e.toString());
    }
  }

  // ── Admin: booking report ────────────────────────────────────────────
  Future<Map<String, dynamic>> getBookingReport(String eventId) async {
    final vehiclesSnap = await _firestore
        .collection('vehicles')
        .where('eventId', isEqualTo: eventId)
        .get();

    final rsvpsSnap = await _firestore
        .collection('rsvp')
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: 'attending')
        .where('needsTransport', isEqualTo: true)
        .get();

    final bookingsSnap = await _firestore
        .collection('seatBookings')
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: 'confirmed')
        .get();

    int totalSeats = 0;
    int bookedSeats = 0;
    for (final doc in vehiclesSnap.docs) {
      final v = VehicleModel.fromFirestore(doc);
      totalSeats += v.totalSeats;
      bookedSeats += v.bookedSeats;
    }

    return {
      'totalVehicles': vehiclesSnap.docs.length,
      'totalSeats': totalSeats,
      'bookedSeats': bookedSeats,
      'availableSeats': totalSeats - bookedSeats,
      'confirmedRsvps': rsvpsSnap.docs.length,
      'bookedMembers': bookingsSnap.docs.length,
      'unbookedMembers': rsvpsSnap.docs.length - bookingsSnap.docs.length,
      'occupancyRate': totalSeats > 0
          ? (bookedSeats / totalSeats * 100).toStringAsFixed(1)
          : '0',
    };
  }
}
