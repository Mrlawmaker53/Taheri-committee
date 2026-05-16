import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/models/event_announcement_model.dart';

class EventAnnouncementController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxList<EventAnnouncementModel> announcements =
      <EventAnnouncementModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    _listenAnnouncements();
  }

  void _listenAnnouncements() {
    final auth = Get.find<AuthController>();
    Query q = _db
        .collection('eventAnnouncements')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true);

    // Filter by user's groups if not admin
    if (!auth.isLeader) {
      final teamId = auth.teamId;
      if (teamId.isNotEmpty) {
        q = q.where('targetGroups', arrayContainsAny: [teamId]);
      }
    }

    q.snapshots().listen((snap) {
      announcements.value = snap.docs
          .map((doc) => EventAnnouncementModel.fromFirestore(doc))
          .toList();
      hasLoaded.value = true;
    });
  }

  Future<void> createAnnouncement({
    required String title,
    required String description,
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
    DateTime? deadlineAt,
    List<String> targetGroups = const [],
  }) async {
    final auth = Get.find<AuthController>();
    isLoading.value = true;

    try {
      final announcement = EventAnnouncementModel(
        id: '', // Will be set by Firestore
        title: title,
        description: description,
        eventId: eventId,
        eventTitle: eventTitle,
        eventDate: eventDate,
        createdBy: auth.uid,
        createdByName: auth.displayName,
        createdAt: DateTime.now(),
        deadlineAt: deadlineAt,
        targetGroups: targetGroups.isEmpty ? ['all'] : targetGroups,
      );

      await _db.collection('eventAnnouncements').add(announcement.toMap());

      Get.back();
      Get.snackbar(
        'Success',
        'Event announcement created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create announcement: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> respondToAnnouncement({
    required String announcementId,
    required String response,
    String? note,
  }) async {
    final auth = Get.find<AuthController>();
    isLoading.value = true;

    try {
      final attendanceResponse = AttendanceResponse(
        response: response,
        respondedAt: DateTime.now(),
        note: note,
      );

      await _db.collection('eventAnnouncements').doc(announcementId).update({
        'responses.${auth.uid}': attendanceResponse.toMap(),
      });

      Get.snackbar(
        'Response Recorded',
        'Your attendance response has been saved',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save response: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deactivateAnnouncement(String announcementId) async {
    try {
      await _db.collection('eventAnnouncements').doc(announcementId).update({
        'isActive': false,
      });

      Get.snackbar(
        'Deactivated',
        'Announcement has been deactivated',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to deactivate: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  AttendanceResponse? getUserResponse(String announcementId) {
    final auth = Get.find<AuthController>();
    final announcement =
        announcements.firstWhereOrNull((a) => a.id == announcementId);
    return announcement?.responses[auth.uid];
  }

  bool hasUserResponded(String announcementId) {
    final response = getUserResponse(announcementId);
    return response != null && response.response != 'pending';
  }

  List<EventAnnouncementModel> getActiveAnnouncements() {
    return announcements.where((a) => a.isActive).toList();
  }

  List<EventAnnouncementModel> getPendingUserResponses() {
    final auth = Get.find<AuthController>();
    return announcements
        .where((a) =>
            a.isActive && !a.responses.containsKey(auth.uid) ||
            a.responses[auth.uid]?.response == 'pending')
        .toList();
  }

  List<EventAnnouncementModel> getYesResponders() {
    final auth = Get.find<AuthController>();
    if (!auth.isSupervisorOrLeader) return [];

    return announcements.where((a) => a.isActive).toList();
  }
}
