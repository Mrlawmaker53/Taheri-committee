// Transport Setup Service
// Use this to initialize required Firebase collections for seat booking

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../models/transport_model.dart';
import '../models/seat_booking_model.dart';

class TransportSetupService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Initialize sample transport data for testing
  /// Call this from admin panel or development environment
  static Future<void> initializeSampleData() async {
    try {
      debugPrint('🚀 Initializing sample transport data...');

      // Get current user's team ID
      final auth = Get.find<AuthController>();
      final teamId = auth.currentUser.value?.teamId ?? 'team_001';

      // Create sample transport 1 - Cruiser
      const transportId1 = 'transport_001';
      final transport1 = TransportModel(
        id: transportId1,
        vehicleLabel: 'Toyota Cruiser - Main Vehicle',
        driverName: 'Ahmed Hassan',
        route: 'Central Mosque → Event Venue',
        vehicleType: VehicleType.cruiser,
        teamId: teamId,
        status: 'active',
        eventId: 'event_001',
        eventTitle: 'Friday Prayers Transport',
        departureTime: DateTime.now().add(const Duration(hours: 5)),
        returnTime: DateTime.now().add(const Duration(hours: 9)),
        pickupPoint: 'Central Mosque Parking',
        contactPerson: 'Transport Coordinator',
        priority: 'high',
        currentBookings: 0,
        waitingList: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _db
          .collection('transport')
          .doc(transportId1)
          .set(transport1.toMap());
      debugPrint('✅ Created transport: $transportId1');

      // Create sample transport 2 - Eeco
      const transportId2 = 'transport_002';
      final transport2 = TransportModel(
        id: transportId2,
        vehicleLabel: 'Suzuki Eeco - Backup Vehicle',
        driverName: 'Mohammed Ali',
        route: 'Secondary Route → Event Venue',
        vehicleType: VehicleType.eeco,
        teamId: teamId,
        status: 'active',
        eventId: 'event_001',
        eventTitle: 'Friday Prayers Transport',
        departureTime:
            DateTime.now().add(const Duration(hours: 5, minutes: 30)),
        returnTime: DateTime.now().add(const Duration(hours: 9, minutes: 30)),
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
          .doc(transportId2)
          .set(transport2.toMap());
      debugPrint('✅ Created transport: $transportId2');

      // Verify subcollections are accessible
      await _verifySubcollections(transportId1);
      await _verifySubcollections(transportId2);

      debugPrint('\n🎉 Transport setup completed successfully!');
      debugPrint('\n📋 Summary:');
      debugPrint('- Created 2 sample transport vehicles');
      debugPrint('- Initialized bookings subcollections');
      debugPrint('- Initialized waiting list subcollections');
      debugPrint('- Ready for member seat booking');
    } catch (e) {
      debugPrint('❌ Error setting up transport data: $e');
      rethrow;
    }
  }

  /// Verify that subcollections exist and are accessible
  static Future<void> _verifySubcollections(String transportId) async {
    try {
      // Test bookings subcollection
      final bookingsRef = _db
          .collection('transport')
          .doc(transportId)
          .collection('bookings')
          .limit(1);
      await bookingsRef.get();
      debugPrint('✅ Bookings subcollection accessible for $transportId');

      // Test waiting list subcollection
      final waitingListRef = _db
          .collection('transport')
          .doc(transportId)
          .collection('waitingList')
          .limit(1);
      await waitingListRef.get();
      debugPrint('✅ Waiting list subcollection accessible for $transportId');
    } catch (e) {
      debugPrint('❌ Error accessing subcollections for $transportId: $e');
      rethrow;
    }
  }

  /// Check if transport data exists
  static Future<bool> hasTransportData() async {
    try {
      final snapshot = await _db.collection('transport').limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking transport data: $e');
      return false;
    }
  }

  /// Get transport count for current user's team
  static Future<int> getTransportCount() async {
    try {
      final auth = Get.find<AuthController>();
      final teamId = auth.currentUser.value?.teamId;

      QuerySnapshot snapshot;
      if (auth.isLeader) {
        snapshot = await _db.collection('transport').get();
      } else {
        snapshot = await _db
            .collection('transport')
            .where('teamId', isEqualTo: teamId)
            .get();
      }

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Error getting transport count: $e');
      return 0;
    }
  }

  /// Clear all transport data (for testing/reset)
  static Future<void> clearAllTransportData() async {
    try {
      debugPrint('🧹 Clearing all transport data...');

      final snapshot = await _db.collection('transport').get();

      for (final doc in snapshot.docs) {
        // Delete bookings subcollection
        final bookings = await doc.reference.collection('bookings').get();
        for (final booking in bookings.docs) {
          await booking.reference.delete();
        }

        // Delete waiting list subcollection
        final waitingList = await doc.reference.collection('waitingList').get();
        for (final waiting in waitingList.docs) {
          await waiting.reference.delete();
        }

        // Delete main transport document
        await doc.reference.delete();
      }

      debugPrint('✅ All transport data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing transport data: $e');
      rethrow;
    }
  }
}
