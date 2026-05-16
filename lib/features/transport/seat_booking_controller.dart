import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/models/seat_booking_model.dart';
import '../../core/models/waiting_list_model.dart';

class SeatBookingController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── State ──────────────────────────────────────────────
  final RxMap<String, SeatBookingModel> bookings =
      <String, SeatBookingModel>{}.obs; // seatId → booking
  final RxString selectedSeatId = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasLoaded = false.obs;

  // 🆕 Waiting list state
  final RxMap<String, WaitingListModel> waitingList =
      <String, WaitingListModel>{}.obs; // userId → waiting list entry
  final RxBool isOnWaitingList = false.obs;

  // Set from outside before navigating to SeatMapScreen
  String transportId = '';
  VehicleType vehicleType = VehicleType.cruiser;
  String eventId = ''; // 🆕 Event context
  String eventTitle = ''; // 🆕 Event context

  // ── Derived ────────────────────────────────────────────
  AuthController get _auth => Get.find<AuthController>();
  String get _uid => _auth.uid;
  String get _name => _auth.displayName;
  String get _avatar => _auth.currentUser.value?.avatarUrl ?? '';

  /// Returns the seatId the current user has booked (or null).
  String? get myBookedSeatId {
    for (final entry in bookings.entries) {
      if (entry.value.userId == _uid) return entry.key;
    }
    return null;
  }

  bool get iHaveASeat => myBookedSeatId != null;

  int get bookedCount => bookings.length;
  int get availableCount => vehicleType.passengerCount - bookedCount;

  // ── Lifecycle ──────────────────────────────────────────
  @override
  void onClose() {
    _bookingsSub?.cancel();
    _waitingSub?.cancel();
    super.onClose();
  }

  StreamSubscription<QuerySnapshot>? _bookingsSub;
  StreamSubscription<QuerySnapshot>? _waitingSub;

  /// Call this right after setting [transportId] and [vehicleType].
  void startListening() {
    _bookingsSub?.cancel();
    _waitingSub?.cancel();

    // 🆕 Listen to bookings
    _bookingsSub = _db
        .collection('transport')
        .doc(transportId)
        .collection('bookings')
        .snapshots()
        .listen((snap) {
      final map = <String, SeatBookingModel>{};
      for (final doc in snap.docs) {
        map[doc.id] = SeatBookingModel.fromFirestore(doc);
      }
      bookings.value = map;
      hasLoaded.value = true;
    });

    // 🆕 Listen to waiting list
    _waitingSub = _db
        .collection('transport')
        .doc(transportId)
        .collection('waitingList')
        .snapshots()
        .listen((snap) {
      final map = <String, WaitingListModel>{};
      for (final doc in snap.docs) {
        map[doc.id] = WaitingListModel.fromFirestore(doc);
      }
      waitingList.value = map;
      isOnWaitingList.value = map.containsKey(_uid);
    });
  }

  // ── Select / Deselect ──────────────────────────────────
  void selectSeat(String seatId) {
    if (bookings[seatId] != null && bookings[seatId]!.userId != _uid) {
      // Taken by someone else — show who
      Get.snackbar(
        'Seat Taken',
        'This seat is booked by ${bookings[seatId]!.displayName}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1A237E).withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    if (iHaveASeat && myBookedSeatId != seatId) {
      Get.snackbar(
        'Already Booked',
        'You have seat $myBookedSeatId. Release it first.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }
    // Toggle selection
    selectedSeatId.value = selectedSeatId.value == seatId ? '' : seatId;
  }

  // ── Book ───────────────────────────────────────────────
  Future<void> confirmBooking() async {
    final seatId = selectedSeatId.value;
    if (seatId.isEmpty) return;
    isLoading.value = true;
    try {
      final seatRef = _db
          .collection('transport')
          .doc(transportId)
          .collection('bookings')
          .doc(seatId);

      await _db.runTransaction((txn) async {
        final snap = await txn.get(seatRef);
        if (snap.exists) {
          throw Exception('Seat $seatId was just taken. Pick another.');
        }
        txn.set(
            seatRef,
            SeatBookingModel(
              seatId: seatId,
              userId: _uid,
              displayName: _name,
              avatarUrl: _avatar,
              bookedAt: DateTime.now(),
            ).toMap());
      });

      selectedSeatId.value = '';
      Get.snackbar(
        'Booked! ✓',
        'Seat $seatId is yours. See you there.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF00897B).withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        'Booking Failed',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade900.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Release my seat ────────────────────────────────────
  Future<void> releaseSeat() async {
    final seatId = myBookedSeatId;
    if (seatId == null) return;
    isLoading.value = true;
    try {
      await _db
          .collection('transport')
          .doc(transportId)
          .collection('bookings')
          .doc(seatId)
          .delete();
      selectedSeatId.value = '';
      Get.snackbar(
        'Seat Released',
        'Seat $seatId is now available.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade900.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar('Error', 'Could not release seat: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // ── Admin: force release any seat ─────────────────────
  Future<void> adminRelease(String seatId) async {
    try {
      await _db
          .collection('transport')
          .doc(transportId)
          .collection('bookings')
          .doc(seatId)
          .delete();
      Get.snackbar('Released', 'Seat $seatId released.',
          snackPosition: SnackPosition.BOTTOM);

      // 🆕 Notify next person on waiting list
      await _notifyNextOnWaitingList();
    } catch (e) {
      Get.snackbar('Error', '$e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ── 🆕 Waiting List Management ─────────────────────────

  /// Add user to waiting list when transport is full
  Future<void> addToWaitingList({
    String? contactNumber,
    String priority = 'member',
  }) async {
    if (isOnWaitingList.value) {
      Get.snackbar('Already on List', 'You are already on the waiting list.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;
    try {
      await _db
          .collection('transport')
          .doc(transportId)
          .collection('waitingList')
          .doc(_uid)
          .set(WaitingListModel(
            userId: _uid,
            displayName: _name,
            eventId: eventId,
            transportId: transportId,
            requestedAt: DateTime.now(),
            priority: priority,
            contactNumber: contactNumber,
          ).toMap());

      // Update transport waiting list count
      await _db.collection('transport').doc(transportId).update({
        'waitingList': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });

      Get.snackbar('Added to Waiting List',
          'We\'ll notify you when a seat becomes available.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to join waiting list: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// Remove user from waiting list
  Future<void> removeFromWaitingList() async {
    if (!isOnWaitingList.value) return;

    isLoading.value = true;
    try {
      await _db
          .collection('transport')
          .doc(transportId)
          .collection('waitingList')
          .doc(_uid)
          .delete();

      // Update transport waiting list count
      await _db.collection('transport').doc(transportId).update({
        'waitingList': FieldValue.increment(-1),
        'updatedAt': Timestamp.now(),
      });

      Get.snackbar('Removed', 'You have been removed from the waiting list.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to leave waiting list: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// Notify next person on waiting list when seat becomes available
  Future<void> _notifyNextOnWaitingList() async {
    try {
      // Get waiting list ordered by priority
      final snap = await _db
          .collection('transport')
          .doc(transportId)
          .collection('waitingList')
          .where('status', isEqualTo: 'waiting')
          .orderBy('priority')
          .orderBy('requestedAt')
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final nextUser = snap.docs.first;
        // Update status to notified
        await nextUser.reference.update({'status': 'notified'});

        // In a real app, you would send push notification here
        Get.snackbar('Seat Available',
            'Notified next person on waiting list: ${nextUser['displayName']}',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      print('Error notifying waiting list: $e');
    }
  }

  /// Get waiting list position for current user
  int get myWaitingListPosition {
    if (!isOnWaitingList.value) return 0;

    final sortedList = waitingList.values
        .where((w) => w.status == 'waiting')
        .toList()
      ..sort((a, b) {
        final priorityCompare = WaitingListModel.getPriorityValue(a.priority)
            .compareTo(WaitingListModel.getPriorityValue(b.priority));
        if (priorityCompare != 0) return priorityCompare;
        return a.requestedAt.compareTo(b.requestedAt);
      });

    for (int i = 0; i < sortedList.length; i++) {
      if (sortedList[i].userId == _uid) return i + 1;
    }
    return 0;
  }
}
