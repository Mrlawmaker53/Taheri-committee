import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/models/event_model.dart';
import '../../core/models/rsvp_model.dart';
import '../../core/services/activity_log_service.dart';

class EventsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxList<EventModel> events = <EventModel>[].obs;
  final RxList<RsvpModel> myRsvps = <RsvpModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    listenEvents();
    _listenMyRsvps();
  }

  @override
  Future<void> refresh() async => listenEvents();

  void listenEvents() {
    _db
        .collection('events')
        .orderBy('eventDate', descending: false)
        .snapshots()
        .listen((snap) {
      events.value = snap.docs.map((d) => EventModel.fromFirestore(d)).toList();
      hasLoaded.value = true;
    }, onError: (_) => hasLoaded.value = true);
  }

  void _listenMyRsvps() {
    final uid = Get.find<AuthController>().uid;
    if (uid.isEmpty) return;
    _db
        .collection('rsvp')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
      myRsvps.value = snap.docs.map((d) => RsvpModel.fromFirestore(d)).toList();
    });
  }

  String? rsvpStatusFor(String eventId) {
    try {
      return myRsvps.firstWhere((r) => r.eventId == eventId).status;
    } catch (_) {
      return null;
    }
  }

  bool needsTransportFor(String eventId) {
    try {
      return myRsvps.firstWhere((r) => r.eventId == eventId).needsTransport;
    } catch (_) {
      return false;
    }
  }

  Future<void> submitRsvp(String eventId, String status,
      {bool needsTransport = false}) async {
    final uid = Get.find<AuthController>().uid;
    if (uid.isEmpty) return;
    isLoading.value = true;
    try {
      final existing = myRsvps.firstWhereOrNull((r) => r.eventId == eventId);
      if (existing != null) {
        await _db.collection('rsvp').doc(existing.rsvpId).update({
          'status': status,
          'needsTransport': needsTransport,
          'respondedAt': Timestamp.now(),
        });
      } else {
        await _db.collection('rsvp').add({
          'eventId': eventId,
          'userId': uid,
          'status': status,
          'needsTransport': needsTransport,
          'respondedAt': Timestamp.now(),
        });
      }
      Get.snackbar('RSVP Updated', 'Your RSVP has been recorded.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit RSVP: $e',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createEvent({
    required String title,
    required DateTime eventDate,
    required String location,
    required bool rsvpEnabled,
    required bool attendanceEnabled,
    String targetType = 'all', // all | team | role
    String? targetTeamId,
    String? targetRole,
  }) async {
    final auth = Get.find<AuthController>();
    isLoading.value = true;
    try {
      final ref = await _db.collection('events').add({
        'title': title,
        'createdBy': auth.uid,
        'createdByName': auth.displayName,
        'eventDate': Timestamp.fromDate(eventDate),
        'location': location,
        'rsvpEnabled': rsvpEnabled,
        'attendanceEnabled': attendanceEnabled,
        // ─── targeting (read by onEventCreated cloud function) ───
        'targetType': targetType,
        if (targetTeamId != null) 'targetTeamId': targetTeamId,
        if (targetRole != null) 'targetRole': targetRole,
      });
      await ActivityLogService.log(
        action: 'event_created',
        targetId: ref.id,
        targetType: 'event',
        targetName: title,
      );
      Get.back();
      Get.snackbar('Success', 'Event created successfully.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to create event: $e',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}
