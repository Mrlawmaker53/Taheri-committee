import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/services/activity_log_service.dart';
import '../../core/services/hive_service.dart';
import '../../core/controllers/connectivity_controller.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final String audience;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.audience,
  });

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      audience: data['audience'] ?? 'all',
    );
  }

  factory AnnouncementModel.fromMap(String id, Map<String, dynamic> data) {
    return AnnouncementModel(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      createdAt: data['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : DateTime.now(),
      audience: data['audience'] ?? 'all',
    );
  }
}

class AnnouncementsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxList<AnnouncementModel> announcements = <AnnouncementModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    _listenAnnouncements();
  }

  void _listenAnnouncements() {
    final conn = Get.find<ConnectivityController>();
    if (!conn.isConnected.value) {
      _loadCachedAnnouncements();
      return;
    }
    _db
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      announcements.value =
          snap.docs.map((d) => AnnouncementModel.fromFirestore(d)).toList();
      hasLoaded.value = true;
      for (final d in snap.docs) {
        HiveService.cacheAnnouncement(
            d.id, {'title': (d.data() as Map)['title'] ?? ''});
      }
    }, onError: (_) => hasLoaded.value = true);
  }

  void _loadCachedAnnouncements() {
    final cached = HiveService.getCachedAnnouncements();
    announcements.value =
        cached.map((m) => AnnouncementModel.fromMap(m['id'] ?? '', m)).toList();
    hasLoaded.value = true;
  }

  /// Create an announcement. The Cloud Function `onAnnouncementCreated` will
  /// read the target fields and dispatch FCM to the right recipients.
  Future<void> createAnnouncement({
    required String title,
    required String body,
    required String audience,
    String targetType = 'all', // all | team | role | individual
    String? targetTeamId,
    String? targetRole,
    String? targetUserId,
    bool requiresResponse = false,
    List<String> responseOptions = const [],
  }) async {
    final auth = Get.find<AuthController>();
    isLoading.value = true;
    try {
      final ref = await _db.collection('announcements').add({
        'title': title,
        'body': body,
        'authorId': auth.uid,
        'authorName': auth.displayName,
        'createdBy': auth.uid,
        'createdByName': auth.displayName,
        'createdAt': Timestamp.now(),
        'audience': audience,
        // ─── targeting (read by onAnnouncementCreated cloud function) ───
        'targetType': targetType,
        if (targetTeamId != null) 'targetTeamId': targetTeamId,
        if (targetRole != null) 'targetRole': targetRole,
        if (targetUserId != null) 'targetUserId': targetUserId,
        // ─── response config ───
        'requiresResponse': requiresResponse,
        'responseOptions': responseOptions,
      });
      await ActivityLogService.log(
        action: 'announcement_published',
        targetId: ref.id,
        targetType: 'announcement',
        targetName: title,
      );
      Get.back();
      Get.snackbar('Published', 'Announcement sent to $audience.',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
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

  Future<void> deleteAnnouncement(String id) async {
    try {
      await _db.collection('announcements').doc(id).delete();
      Get.snackbar('Deleted', 'Announcement removed.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
