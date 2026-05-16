import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/models/event_model.dart';
import '../../../core/models/vehicle_model.dart';
import '../../../core/models/new_seat_booking_model.dart';
import '../../../core/services/booking_service.dart';

class BookingController extends GetxController {
  final BookingService _service = BookingService();

  // ── State ────────────────────────────────────────────────────────────
  final Rx<EventModel?> event = Rx<EventModel?>(null);
  final RxList<VehicleModel> vehicles = <VehicleModel>[].obs;
  final RxList<NewSeatBookingModel> eventBookings =
      <NewSeatBookingModel>[].obs;
  final Rx<NewSeatBookingModel?> myBooking = Rx<NewSeatBookingModel?>(null);
  final Rx<Map<String, dynamic>> report = Rx<Map<String, dynamic>>({});

  final RxBool isLoading = false.obs;
  final RxBool isBooking = false.obs;
  final RxBool hasLoaded = false.obs;

  StreamSubscription? _vehicleSub;
  StreamSubscription? _bookingSub;

  AuthController get _auth => Get.find<AuthController>();

  // ── Lifecycle ────────────────────────────────────────────────────────
  @override
  void onClose() {
    _vehicleSub?.cancel();
    _bookingSub?.cancel();
    super.onClose();
  }

  /// Call after setting the event to start real-time listeners.
  Future<void> initForEvent(EventModel ev) async {
    event.value = ev;
    isLoading.value = true;
    hasLoaded.value = false;

    _vehicleSub?.cancel();
    _bookingSub?.cancel();

    // Listen to vehicles
    _vehicleSub =
        _service.getEventVehicles(ev.eventId).listen((list) {
      vehicles.value = list;
      hasLoaded.value = true;
      isLoading.value = false;
    });

    // Listen to all bookings for this event
    _bookingSub =
        _service.getEventBookings(ev.eventId).listen((list) {
      eventBookings.value = list;
    });

    // Load user's existing booking
    await _loadMyBooking(ev.eventId);
  }

  Future<void> _loadMyBooking(String eventId) async {
    final uid = _auth.uid;
    if (uid.isEmpty) return;
    myBooking.value = await _service.getUserBooking(eventId, uid);
  }

  // ── Member: Book a seat ──────────────────────────────────────────────
  Future<void> bookSeat(String vehicleId) async {
    final ev = event.value;
    if (ev == null) return;
    isBooking.value = true;

    final user = _auth.currentUser.value;
    final userData = {
      'displayName': user?.fullName ?? 'User',
      'avatarUrl': user?.avatarUrl,
      'mobile': user?.mobile,
      'teamId': user?.teamId ?? '',
      'teamName': '', // Will be resolved from team doc if needed
    };

    final result = await _service.bookSeat(
      eventId: ev.eventId,
      vehicleId: vehicleId,
      userData: userData,
    );

    isBooking.value = false;

    if (result.isSuccess) {
      myBooking.value = result.data;
      Get.snackbar(
        'Seat Booked!',
        'Your seat has been confirmed. Booking code: ${result.data!.bookingCode}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
        duration: const Duration(seconds: 4),
      );
    } else {
      Get.snackbar(
        'Booking Failed',
        result.error ?? 'Unknown error',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // ── Member: Cancel booking ───────────────────────────────────────────
  Future<void> cancelBooking() async {
    final booking = myBooking.value;
    if (booking == null) return;
    isBooking.value = true;

    final result = await _service.cancelBooking(booking.id);
    isBooking.value = false;

    if (result.isSuccess) {
      myBooking.value = null;
      Get.snackbar(
        'Booking Cancelled',
        'Your seat has been released',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
      );
    } else {
      Get.snackbar(
        'Error',
        result.error ?? 'Could not cancel booking',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    }
  }

  // ── Admin: Create vehicle ────────────────────────────────────────────
  Future<bool> createVehicle({
    required String name,
    required String type,
    required int totalSeats,
    required DateTime departureTime,
    String? route,
    String? driverName,
    String? driverMobile,
  }) async {
    final ev = event.value;
    if (ev == null) return false;
    isLoading.value = true;

    final result = await _service.createVehicle(
      eventId: ev.eventId,
      name: name,
      type: type,
      totalSeats: totalSeats,
      departureTime: departureTime,
      route: route,
      driverName: driverName,
      driverMobile: driverMobile,
    );

    isLoading.value = false;

    if (result.isSuccess) {
      Get.snackbar(
        'Vehicle Created',
        '$name added with $totalSeats seats',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );
      return true;
    } else {
      Get.snackbar(
        'Error',
        result.error ?? 'Failed to create vehicle',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return false;
    }
  }

  // ── Admin: Delete vehicle ────────────────────────────────────────────
  Future<void> deleteVehicle(String vehicleId) async {
    isLoading.value = true;
    final result = await _service.deleteVehicle(vehicleId);
    isLoading.value = false;

    if (result.isSuccess) {
      Get.snackbar('Deleted', 'Vehicle removed',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Error', result.error ?? 'Failed to delete',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900);
    }
  }

  // ── Admin: Load report ───────────────────────────────────────────────
  Future<void> loadReport() async {
    final ev = event.value;
    if (ev == null) return;
    report.value = await _service.getBookingReport(ev.eventId);
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  List<NewSeatBookingModel> bookingsForVehicle(String vehicleId) {
    return eventBookings.where((b) => b.vehicleId == vehicleId).toList();
  }
}
