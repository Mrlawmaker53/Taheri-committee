import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/models/user_model.dart';
import '../../core/services/activity_log_service.dart';

class AdminController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxList<UserModel> allUsers = <UserModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    _listenUsers();
  }

  void _listenUsers() {
    _db.collection('users').orderBy('fullName').snapshots().listen((snap) {
      allUsers.value =
          snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
      hasLoaded.value = true;
    }, onError: (_) => hasLoaded.value = true);
  }

  Future<void> updateRole(UserModel user, String newRole) async {
    isLoading.value = true;
    try {
      await _db.collection('users').doc(user.uid).update({'role': newRole});
      await ActivityLogService.log(
        action: 'member_role_changed',
        targetId: user.uid,
        targetType: 'user',
        targetName: user.fullName,
        note: '${user.role} → $newRole',
      );
      Get.snackbar(
          'Updated', '${user.fullName} is now a ${_roleLabel(newRole)}.',
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

  Future<void> setActive(UserModel user, bool active) async {
    isLoading.value = true;
    try {
      await _db.collection('users').doc(user.uid).update({'isActive': active});
      Get.snackbar(
        active ? 'Activated' : 'Deactivated',
        '${user.fullName} account ${active ? 'activated' : 'deactivated'}.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed: $e',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> moveUserToTeam(
      String uid, String teamId, String fullName) async {
    isLoading.value = true;
    try {
      await _db.collection('users').doc(uid).update({'teamId': teamId});
      await ActivityLogService.log(
        action: 'member_team_moved',
        targetId: uid,
        targetType: 'user',
        targetName: fullName,
        note: 'Moved to team $teamId',
      );
      Get.snackbar('Done', '$fullName moved to new team.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createUserAccount({
    required String email,
    required String fullName,
    required String role,
    required String teamId,
    String mobile = '',
    String address = '',
    String emergencyContact = '',
    String itsNo = '',
    DateTime? dateOfBirth,
    DateTime? joinDate,
    String pickupId = '',
  }) async {
    isLoading.value = true;
    try {
      await _db.collection('users').add({
        'email': email,
        'mobile': mobile,
        'fullName': fullName,
        'role': role,
        'teamId': teamId,
        'address': address,
        'emergencyContact': emergencyContact,
        'itsNo': itsNo,
        'dateOfBirth':
            dateOfBirth != null ? Timestamp.fromDate(dateOfBirth) : null,
        'joinDate':
            joinDate != null ? Timestamp.fromDate(joinDate) : Timestamp.now(),
        'pickupId': pickupId,
        'isActive': true,
        'avatarUrl': '',
        'createdAt': Timestamp.now(),
      });
      Get.snackbar('Created', 'User record created. Send invite separately.',
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

  // ───────────────────────────────────────────────────────────────────────
  // Team CRUD (leader only) — surfaced in ManageTeamsScreen.
  // Firestore rules: /teams allows create/update/delete for leader/admin.
  // ───────────────────────────────────────────────────────────────────────
  Future<void> createTeam({
    required String teamName,
    String supervisorId = '',
    String leaderId = '',
  }) async {
    isLoading.value = true;
    try {
      final ref = await _db.collection('teams').add({
        'teamName': teamName.trim(),
        'supervisorId': supervisorId,
        'leaderId': leaderId,
        'memberCount': 0,
        'createdAt': Timestamp.now(),
      });
      await ActivityLogService.log(
        action: 'team_created',
        targetId: ref.id,
        targetType: 'team',
        targetName: teamName.trim(),
      );
      Get.snackbar('Team created', '"${teamName.trim()}" added.',
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

  Future<void> updateTeam({
    required String teamId,
    required String teamName,
    String? supervisorId,
    String? leaderId,
  }) async {
    isLoading.value = true;
    try {
      final updates = <String, dynamic>{
        'teamName': teamName.trim(),
      };
      if (supervisorId != null) updates['supervisorId'] = supervisorId;
      if (leaderId != null) updates['leaderId'] = leaderId;
      await _db.collection('teams').doc(teamId).update(updates);
      await ActivityLogService.log(
        action: 'team_updated',
        targetId: teamId,
        targetType: 'team',
        targetName: teamName.trim(),
      );
      Get.snackbar('Team updated', '"${teamName.trim()}" saved.',
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

  /// Delete a team. Refuses if any users are still assigned to it so we
  /// don't orphan accounts. Caller should reassign members first.
  Future<bool> deleteTeam(String teamId, String teamName) async {
    isLoading.value = true;
    try {
      final assigned = await _db
          .collection('users')
          .where('teamId', isEqualTo: teamId)
          .limit(1)
          .get();
      if (assigned.docs.isNotEmpty) {
        Get.snackbar(
            'Cannot delete', 'Reassign all members out of "$teamName" first.',
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.orange.shade900,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4));
        return false;
      }
      await _db.collection('teams').doc(teamId).delete();
      await ActivityLogService.log(
        action: 'team_deleted',
        targetId: teamId,
        targetType: 'team',
        targetName: teamName,
      );
      Get.snackbar('Team deleted', '"$teamName" removed.',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          snackPosition: SnackPosition.BOTTOM);
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

  String _roleLabel(String role) {
    switch (role) {
      case 'leader':
      case 'admin':
        return 'Leader';
      case 'supervisor':
        return 'Supervisor';
      default:
        return 'Member';
    }
  }

  List<UserModel> get leaders => allUsers.where((u) => u.isLeader).toList();
  List<UserModel> get supervisors =>
      allUsers.where((u) => u.isSupervisor).toList();
  List<UserModel> get members => allUsers.where((u) => u.isMember).toList();
}
