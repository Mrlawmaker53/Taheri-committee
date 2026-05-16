// lib/features/transport/transport_controller.dart
// UPDATED: createTransport now accepts vehicleType.
// All other logic is unchanged from original.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/models/transport_model.dart';
import '../../core/models/seat_booking_model.dart'; // ← NEW

class TransportController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxList<TransportModel> transports = <TransportModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    _listenTransport();
  }

  void _listenTransport() {
    final auth = Get.find<AuthController>();
    Query q = _db.collection('transport');
    if (!auth.isLeader) {
      q = q.where('teamId', isEqualTo: auth.teamId);
    }
    q.snapshots().listen((snap) {
      try {
        transports.value =
            snap.docs.map((d) => TransportModel.fromFirestore(d)).toList();
      } catch (e) {
        debugPrint('Error parsing transport documents: $e');
        transports.value = [];
      }
      hasLoaded.value = true;
    }, onError: (error) {
      debugPrint('Transport stream error: $error');
      transports.value = [];
      hasLoaded.value = true;
    });
  }

  Future<void> createTransport({
    required String eventId, // 🆕 Required event linkage
    required String eventTitle,
    required String teamId,
    required String vehicleLabel,
    required String driverName,
    required String route,
    VehicleType vehicleType = VehicleType.cruiser,
    // 🆕 Enhanced transport management
    DateTime? departureTime,
    DateTime? returnTime,
    String? pickupPoint,
    String? contactPerson,
    String priority = 'medium',
  }) async {
    isLoading.value = true;
    try {
      final now = DateTime.now();
      await _db.collection('transport').add({
        // 🆕 Event linkage
        'eventId': eventId,
        'eventTitle': eventTitle,

        // Existing fields
        'teamId': teamId,
        'vehicleLabel': vehicleLabel,
        'driverName': driverName,
        'status': 'active',
        'route': route,
        'vehicleType': vehicleType == VehicleType.eeco ? 'eeco' : 'cruiser',

        // 🆕 Enhanced transport management
        'departureTime':
            departureTime != null ? Timestamp.fromDate(departureTime) : null,
        'returnTime':
            returnTime != null ? Timestamp.fromDate(returnTime) : null,
        'pickupPoint': pickupPoint,
        'contactPerson': contactPerson,
        'priority': priority,

        // 🆕 Capacity tracking
        'currentBookings': 0,
        'waitingList': 0,

        // 🆕 Metadata
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // 🆕 Update event transport status
      await _db.collection('events').doc(eventId).update({
        'transportStatus': 'active',
        'transportRequired': true,
      });

      Get.back();
      Get.snackbar('Created', 'Transport linked to event successfully.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed: $e',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // Unchanged ────────────────────────────────────────────────
  Future<void> updateStatus(String id, String status) async {
    try {
      await _db.collection('transport').doc(id).update({'status': status});
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deleteTransport(String id) async {
    try {
      // Get transport info before deletion
      final transportDoc = await _db.collection('transport').doc(id).get();
      final eventId = transportDoc['eventId'];

      await _db.collection('transport').doc(id).delete();

      // 🆕 Update event transport status
      await _db.collection('events').doc(eventId).update({
        'transportStatus': 'none',
        'transportRequired': false,
      });

      Get.snackbar('Deleted', 'Transport record removed.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  // 🆕 Get transports for specific event
  Stream<List<TransportModel>> getTransportsForEvent(String eventId) {
    return _db
        .collection('transport')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TransportModel.fromFirestore(d)).toList());
  }

  // 🆕 Update booking count (called when seats are booked/released)
  Future<void> updateBookingCount(String transportId, int delta) async {
    try {
      final transportRef = _db.collection('transport').doc(transportId);
      await transportRef.update({
        'currentBookings': FieldValue.increment(delta),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating booking count: $e');
    }
  }

  // 🆕 Update waiting list count
  Future<void> updateWaitingListCount(String transportId, int delta) async {
    try {
      final transportRef = _db.collection('transport').doc(transportId);
      await transportRef.update({
        'waitingList': FieldValue.increment(delta),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error updating waiting list count: $e');
    }
  }

  // 🆕 Get available events for transport creation
  Future<List<Map<String, dynamic>>> getAvailableEvents() async {
    final auth = Get.find<AuthController>();
    Query q = _db.collection('events');
    if (!auth.isLeader) {
      q = q.where('createdBy', isEqualTo: auth.uid);
    }

    final snap = await q
        .where('eventDate', isGreaterThan: DateTime.now())
        .orderBy('eventDate')
        .get();

    return snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'date':
            (data['eventDate'] as Timestamp).toDate().toString().split(' ')[0],
        'location': data['location'] ?? '',
      };
    }).toList();
  }

  /// Initialize sample transport data for testing (admin/supervisor only)
  Future<void> initializeSampleTransportData() async {
    final auth = Get.find<AuthController>();
    if (!auth.isSupervisorOrLeader) {
      debugPrint('❌ Only supervisors/leaders can initialize transport data');
      return;
    }

    isLoading.value = true;
    try {
      final teamId = auth.teamId;
      if (teamId.isEmpty) {
        debugPrint('❌ No team ID found for current user');
        return;
      }

      // Create sample transport 1 - Cruiser
      final transport1 = TransportModel(
        id: 'transport_001',
        vehicleLabel: 'Toyota Cruiser - Main Vehicle',
        driverName: 'Ahmed Hassan',
        route: 'Main Pickup Point → Event Venue',
        vehicleType: VehicleType.cruiser,
        teamId: teamId,
        status: 'active',
        eventId: 'event_001',
        eventTitle: 'Friday Prayers Transport',
        departureTime:
            DateTime.now().add(const Duration(hours: 5, minutes: 30)),
        returnTime: DateTime.now().add(const Duration(hours: 9, minutes: 30)),
        pickupPoint: 'Main Mosque Parking',
        contactPerson: 'Transport Coordinator',
        priority: 'high',
        currentBookings: 0,
        waitingList: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _db
          .collection('transport')
          .doc('transport_001')
          .set(transport1.toMap());
      debugPrint('✅ Created transport: transport_001');

      // Create sample transport 2 - Eeco
      final transport2 = TransportModel(
        id: 'transport_002',
        vehicleLabel: 'Suzuki Eeco - Backup Vehicle',
        driverName: 'Mohammed Ali',
        route: 'Secondary Route → Event Venue',
        vehicleType: VehicleType.eeco,
        teamId: teamId,
        status: 'active',
        eventId: 'event_001',
        eventTitle: 'Friday Prayers Transport',
        departureTime:
            DateTime.now().add(const Duration(hours: 5, minutes: 45)),
        returnTime: DateTime.now().add(const Duration(hours: 9, minutes: 45)),
        pickupPoint: 'Secondary Pickup Point',
        contactPerson: 'Backup Coordinator',
        priority: 'medium',
        currentBookings: 0,
        waitingList: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _db
          .collection('transport')
          .doc('transport_002')
          .set(transport2.toMap());
      debugPrint('✅ Created transport: transport_002');

      // Initialize empty subcollections for each transport
      await _initializeTransportSubcollections('transport_001');
      await _initializeTransportSubcollections('transport_002');

      debugPrint('\n🎉 Transport data initialized successfully!');
      debugPrint(
          '📋 Created 2 sample transport vehicles with empty subcollections');

      Get.snackbar(
        'Success!',
        'Sample transport data has been initialized',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('❌ Error initializing transport data: $e');
      Get.snackbar(
        'Error',
        'Failed to initialize transport data: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Initialize empty subcollections for a transport
  Future<void> _initializeTransportSubcollections(String transportId) async {
    try {
      // Create empty bookings subcollection (just to ensure it exists)
      final bookingsRef =
          _db.collection('transport').doc(transportId).collection('bookings');

      // Create empty waiting list subcollection (just to ensure it exists)
      final waitingListRef = _db
          .collection('transport')
          .doc(transportId)
          .collection('waitingList');

      // Add a dummy document and delete it to ensure the collection exists
      final dummyBooking = await bookingsRef.add({'dummy': true});
      await dummyBooking.delete();

      final dummyWaiting = await waitingListRef.add({'dummy': true});
      await dummyWaiting.delete();

      debugPrint('✅ Initialized subcollections for $transportId');
    } catch (e) {
      debugPrint(
          '⚠️ Warning: Could not initialize subcollections for $transportId: $e');
    }
  }
}
