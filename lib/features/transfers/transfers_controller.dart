import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/models/transfer_request_model.dart';
import '../../core/services/activity_log_service.dart';

class TransfersController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxList<TransferRequestModel> myRequests =
      <TransferRequestModel>[].obs;
  final RxList<TransferRequestModel> pendingSupervisor =
      <TransferRequestModel>[].obs;
  final RxList<TransferRequestModel> pendingLeader =
      <TransferRequestModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final auth = Get.find<AuthController>();
    _listenMyRequests(auth.uid);
    if (auth.isSupervisorOrLeader) _listenPendingSupervisor();
    if (auth.isLeader) _listenPendingLeader();
  }

  void _listenMyRequests(String uid) {
    if (uid.isEmpty) return;
    _db
        .collection('transfer_requests')
        .where('memberId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      myRequests.value =
          snap.docs.map((d) => TransferRequestModel.fromFirestore(d)).toList();
    });
  }

  void _listenPendingSupervisor() {
    _db
        .collection('transfer_requests')
        .where('status', isEqualTo: 'pending_supervisor')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      pendingSupervisor.value =
          snap.docs.map((d) => TransferRequestModel.fromFirestore(d)).toList();
    });
  }

  void _listenPendingLeader() {
    _db
        .collection('transfer_requests')
        .where('status', isEqualTo: 'pending_leader')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      pendingLeader.value =
          snap.docs.map((d) => TransferRequestModel.fromFirestore(d)).toList();
    });
  }

  Future<void> raiseTransferRequest({
    required String toTeamId,
    required String reason,
  }) async {
    final auth = Get.find<AuthController>();
    isLoading.value = true;
    try {
      final ref = await _db.collection('transfer_requests').add({
        'memberId': auth.uid,
        'fromTeamId': auth.teamId,
        'toTeamId': toTeamId,
        'requestedBy': auth.uid,
        'reason': reason,
        'status': 'pending_supervisor',
        'createdAt': Timestamp.now(),
        'supervisorNote': '',
        'leaderNote': '',
      });
      await ActivityLogService.log(
        action: 'transfer_raised',
        targetId: ref.id,
        targetType: 'transfer',
        targetName: '${auth.displayName} → $toTeamId',
        note: reason,
      );
      Get.back();
      Get.snackbar('Request Sent', 'Transfer request submitted to supervisor.',
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

  Future<void> supervisorApprove(
      TransferRequestModel req, String note) async {
    isLoading.value = true;
    try {
      await _db.collection('transfer_requests').doc(req.id).update({
        'status': 'pending_leader',
        'supervisorNote': note,
      });
      await ActivityLogService.log(
        action: 'transfer_supervisor_approved',
        targetId: req.id,
        targetType: 'transfer',
        targetName: req.memberId,
        note: note,
      );
      Get.snackbar('Approved', 'Transfer forwarded to Leader.',
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

  Future<void> supervisorDecline(
      TransferRequestModel req, String note) async {
    isLoading.value = true;
    try {
      await _db.collection('transfer_requests').doc(req.id).update({
        'status': 'declined',
        'supervisorNote': note,
      });
      await ActivityLogService.log(
        action: 'transfer_supervisor_declined',
        targetId: req.id,
        targetType: 'transfer',
        targetName: req.memberId,
        note: note,
      );
      Get.snackbar('Declined', 'Transfer request declined.',
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

  Future<void> leaderApprove(
      TransferRequestModel req, String note) async {
    isLoading.value = true;
    try {
      final batch = _db.batch();
      batch.update(
          _db.collection('transfer_requests').doc(req.id),
          {'status': 'completed', 'leaderNote': note});
      batch.update(
          _db.collection('users').doc(req.memberId),
          {'teamId': req.toTeamId});
      await batch.commit();
      await ActivityLogService.log(
        action: 'transfer_leader_approved',
        targetId: req.id,
        targetType: 'transfer',
        targetName: req.memberId,
        note: note,
      );
      await ActivityLogService.log(
        action: 'member_team_moved',
        targetId: req.memberId,
        targetType: 'user',
        targetName: req.memberId,
        note: 'Moved to team ${req.toTeamId}',
      );
      Get.snackbar('Completed', 'Member transferred successfully.',
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

  Future<void> leaderDecline(
      TransferRequestModel req, String note) async {
    isLoading.value = true;
    try {
      await _db.collection('transfer_requests').doc(req.id).update({
        'status': 'declined',
        'leaderNote': note,
      });
      await ActivityLogService.log(
        action: 'transfer_leader_declined',
        targetId: req.id,
        targetType: 'transfer',
        targetName: req.memberId,
        note: note,
      );
      Get.snackbar('Declined', 'Transfer request declined.',
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
}
