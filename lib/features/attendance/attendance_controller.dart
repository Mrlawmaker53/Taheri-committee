import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/models/attendance_model.dart';
import '../../core/services/activity_log_service.dart';

class AttendanceController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxList<AttendanceModel> myAttendance = <AttendanceModel>[].obs;
  final RxList<AttendanceModel> teamAttendance = <AttendanceModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString scannedEventId$ = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _listenMyAttendance();
  }

  @override
  Future<void> refresh() async => _listenMyAttendance();

  void _listenMyAttendance() {
    final uid = Get.find<AuthController>().uid;
    if (uid.isEmpty) return;
    _db
        .collection('attendance')
        .where('userId', isEqualTo: uid)
        .orderBy('scannedAt', descending: true)
        .snapshots()
        .listen((snap) {
      myAttendance.value =
          snap.docs.map((d) => AttendanceModel.fromFirestore(d)).toList();
    });
  }

  Future<void> loadTeamAttendance(String eventId) async {
    final auth = Get.find<AuthController>();
    if (!auth.isSupervisorOrLeader) return;
    isLoading.value = true;
    try {
      final snap = await _db
          .collection('attendance')
          .where('eventId', isEqualTo: eventId)
          .get();
      teamAttendance.value =
          snap.docs.map((d) => AttendanceModel.fromFirestore(d)).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load attendance',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // NOTE: Duplicate attendance prevention is app-enforced.
  // Query attendance where eventId+userId before every write.
  // Firestore rules enforce method validity but not uniqueness.
  ///
  /// Returns the event title on success, null otherwise. Caller can use the
  /// return value to drive a success overlay UI without listening to snacks.
  Future<String?> markAttendanceByQR(String scannedEventId) async {
    final auth = Get.find<AuthController>();
    final uid = auth.uid;
    if (uid.isEmpty) return null;
    isLoading.value = true;
    try {
      // Step 1: Verify event exists and attendanceEnabled
      final eventDoc = await _db.collection('events').doc(scannedEventId).get();
      if (!eventDoc.exists) {
        Get.snackbar(
          'Invalid QR',
          'This QR code is not linked to any event.',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }
      final eventData = eventDoc.data()!;
      if (eventData['attendanceEnabled'] != true) {
        Get.snackbar(
          'Not Active',
          'Attendance is not enabled for this event.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }

      // Step 2: Duplicate check
      final existing = await _db
          .collection('attendance')
          .where('eventId', isEqualTo: scannedEventId)
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        Get.snackbar(
          'Already Marked',
          'You have already marked attendance for this event.',
          backgroundColor: Colors.amber.shade100,
          colorText: Colors.amber.shade900,
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }

      // Step 3: Write attendance record
      final docRef = _db.collection('attendance').doc();
      await docRef.set({
        'attendanceId': docRef.id,
        'eventId': scannedEventId,
        'userId': uid,
        'scannedAt': FieldValue.serverTimestamp(),
        'method': 'qr',
      });

      // Step 4: Log activity
      final title = (eventData['title'] ?? scannedEventId).toString();
      await ActivityLogService.log(
        action: 'attendance_marked',
        targetId: scannedEventId,
        targetType: 'event',
        targetName: title,
        note: 'Marked via QR scan',
      );

      scannedEventId$.value = scannedEventId;
      Get.snackbar(
        'Attendance Marked ✓',
        'You are marked present for: $title',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return title;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to mark attendance: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Backward-compat alias used by older callers.
  Future<void> markAttendanceFromQR(String qrData) =>
      markAttendanceByQR(qrData);

  Future<bool> manualMarkAttendance(
      String eventId, String userId, String eventTitle) async {
    isLoading.value = true;
    try {
      // App-enforced duplicate check (Firestore can't do unique compound).
      final existing = await _db
          .collection('attendance')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        Get.snackbar(
          'Already Marked',
          'This member is already marked for the event.',
          backgroundColor: Colors.amber.shade100,
          colorText: Colors.amber.shade900,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      final docRef = _db.collection('attendance').doc();
      await docRef.set({
        'attendanceId': docRef.id,
        'eventId': eventId,
        'userId': userId,
        'scannedAt': FieldValue.serverTimestamp(),
        'method': 'manual',
      });
      await ActivityLogService.log(
        action: 'attendance_marked',
        targetId: eventId,
        targetType: 'event',
        targetName: eventTitle,
        note: 'Marked manually by supervisor',
      );
      Get.snackbar(
        'Done',
        'Attendance marked manually.',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );
      // Refresh report list
      await loadTeamAttendance(eventId);
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed: $e',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
