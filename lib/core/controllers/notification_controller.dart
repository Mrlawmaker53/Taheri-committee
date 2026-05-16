import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../models/notification_model.dart';

class NotificationController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    final auth = Get.find<AuthController>();
    ever(auth.currentUser, (_) => _listenNotifications());
    if (auth.isLoggedIn.value) _listenNotifications();
  }

  void _listenNotifications() {
    final uid = Get.find<AuthController>().uid;
    if (uid.isEmpty) return;
    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
      notifications.value =
          snap.docs.map((d) => NotificationModel.fromFirestore(d)).toList();
      unreadCount.value = notifications.where((n) => !n.isRead).length;
      hasLoaded.value = true;
    }, onError: (_) => hasLoaded.value = true);
  }

  Future<void> markAsRead(String notifId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notifId)
          .update({'isRead': true});
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final uid = Get.find<AuthController>().uid;
    if (uid.isEmpty) return;
    final batch = _firestore.batch();
    final unread = notifications.where((n) => !n.isRead).toList();
    for (final n in unread) {
      batch.update(
          _firestore.collection('notifications').doc(n.id), {'isRead': true});
    }
    await batch.commit();
  }

  /// Submit a member's response to a notification that requires one.
  ///
  /// Writes to `notification_responses/{responseId}`, marks the source
  /// notification as read, and (for `event_rsvp`) also writes to `rsvp/`.
  Future<bool> submitResponse({
    required String notificationId,
    required String response,
    required String type,
    String? eventId,
    String? announcementId,
  }) async {
    final auth = Get.find<AuthController>();
    final uid = auth.currentUid;
    final userName = auth.currentName;
    final teamId = auth.teamId;
    if (uid.isEmpty) return false;

    isLoading.value = true;
    try {
      // 1. Persist response.
      final docRef = _firestore.collection('notification_responses').doc();
      await docRef.set({
        'responseId': docRef.id,
        'notificationId': notificationId,
        'eventId': eventId,
        'announcementId': announcementId,
        'userId': uid,
        'userName': userName,
        'teamId': teamId,
        'response': response,
        'respondedAt': FieldValue.serverTimestamp(),
        'type': type,
      });

      // 2. Mark notification as read.
      try {
        await _firestore
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});
      } catch (_) {}

      // 3. Event RSVPs are mirrored to the rsvp collection.
      if (type == 'event_rsvp' && eventId != null && eventId.isNotEmpty) {
        // Upsert: if user already has an rsvp for this event, update it.
        final existing = await _firestore
            .collection('rsvp')
            .where('userId', isEqualTo: uid)
            .where('eventId', isEqualTo: eventId)
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) {
          await existing.docs.first.reference.update({
            'status': response.toLowerCase(),
            'respondedAt': FieldValue.serverTimestamp(),
          });
        } else {
          final rsvpRef = _firestore.collection('rsvp').doc();
          await rsvpRef.set({
            'rsvpId': rsvpRef.id,
            'eventId': eventId,
            'userId': uid,
            'status': response.toLowerCase(),
            'respondedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      Get.snackbar(
        'Response Sent',
        'Your response has been recorded.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit response: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Has the current user already responded to this notification?
  Future<NotificationResponseModel?> existingResponseFor(
      String notificationId) async {
    final uid = Get.find<AuthController>().uid;
    if (uid.isEmpty) return null;
    final snap = await _firestore
        .collection('notification_responses')
        .where('notificationId', isEqualTo: notificationId)
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return NotificationResponseModel.fromFirestore(snap.docs.first);
  }

  /// Stream all responses to a given notification (sup/leader report screen).
  Stream<List<NotificationResponseModel>> streamResponsesFor(
      String notificationId) {
    return _firestore
        .collection('notification_responses')
        .where('notificationId', isEqualTo: notificationId)
        .orderBy('respondedAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => NotificationResponseModel.fromFirestore(d))
            .toList());
  }
}
