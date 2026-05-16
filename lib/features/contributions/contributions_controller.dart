import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/models/contribution_model.dart';
import '../../core/models/group_request_model.dart';
import '../../core/services/activity_log_service.dart';

class ContributionsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxList<ContributionModel> myContributions = <ContributionModel>[].obs;
  final RxList<ContributionModel> pendingContributions =
      <ContributionModel>[].obs;
  final RxList<ContributionModel> approvedContributions =
      <ContributionModel>[].obs;
  final RxList<GroupRequestModel> groupRequests = <GroupRequestModel>[].obs;
  final RxList<String> selectedContribIds = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasLoadedMine = false.obs;
  final RxBool hasLoadedPending = false.obs;
  final RxBool hasLoadedGroupReqs = false.obs;
  final RxBool hasLoadedFinancial = false.obs;

  // Financial data
  final RxDouble totalFunds = 0.0.obs;
  final RxDouble totalExpenses = 0.0.obs;
  final RxDouble currentBalance = 0.0.obs;
  final RxDouble tripCosts = 0.0.obs;
  final RxDouble otherExpenses = 0.0.obs;
  final RxList<Map<String, dynamic>> recentTransactions =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> expenseBreakdown =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    final auth = Get.find<AuthController>();
    _listenMyContributions(auth.uid);
    if (auth.isSupervisorOrLeader) {
      _listenPendingContributions(auth.uid);
    }
    if (auth.isLeader) {
      _listenGroupRequests();
    }
  }

  void _listenMyContributions(String uid) {
    if (uid.isEmpty) return;
    _db
        .collection('contributions')
        .where('memberId', isEqualTo: uid)
        .orderBy('raisedAt', descending: true)
        .snapshots()
        .listen((snap) {
      myContributions.value =
          snap.docs.map((d) => ContributionModel.fromFirestore(d)).toList();
      hasLoadedMine.value = true;
    }, onError: (_) => hasLoadedMine.value = true);
  }

  void _listenPendingContributions(String supervisorId) {
    _db
        .collection('contributions')
        .where('supervisorId', isEqualTo: supervisorId)
        .where('status', isEqualTo: 'pending')
        .orderBy('raisedAt', descending: true)
        .snapshots()
        .listen((snap) {
      pendingContributions.value =
          snap.docs.map((d) => ContributionModel.fromFirestore(d)).toList();
      hasLoadedPending.value = true;
    }, onError: (_) => hasLoadedPending.value = true);
  }

  void _listenGroupRequests() {
    _db
        .collection('group_requests')
        .where('status', isEqualTo: 'pending_leader')
        .orderBy('raisedAt', descending: true)
        .snapshots()
        .listen((snap) {
      groupRequests.value =
          snap.docs.map((d) => GroupRequestModel.fromFirestore(d)).toList();
      hasLoadedGroupReqs.value = true;
    }, onError: (_) => hasLoadedGroupReqs.value = true);
  }

  Future<void> raiseContribution({
    required double amount,
    required String note,
    required String supervisorId,
  }) async {
    final auth = Get.find<AuthController>();
    isLoading.value = true;
    try {
      final ref = await _db.collection('contributions').add({
        'memberId': auth.uid,
        'supervisorId': supervisorId,
        'teamId': auth.teamId,
        'amount': amount,
        'note': note,
        'status': 'pending',
        'raisedAt': Timestamp.now(),
        'resolvedAt': null,
        'resolvedBy': '',
        'receiptNote': '',
      });
      await ActivityLogService.log(
        action: 'contribution_raised',
        targetId: ref.id,
        targetType: 'contribution',
        targetName: 'INR ${amount.toStringAsFixed(0)}',
        note: note,
      );
      Get.back();
      Get.snackbar('Submitted', 'Contribution request sent to supervisor.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to raise contribution: $e',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveContribution(
      ContributionModel contrib, String receiptNote) async {
    final auth = Get.find<AuthController>();
    isLoading.value = true;
    try {
      await _db.collection('contributions').doc(contrib.id).update({
        'status': 'approved',
        'resolvedAt': Timestamp.now(),
        'resolvedBy': auth.uid,
        'receiptNote': receiptNote,
      });
      await ActivityLogService.log(
        action: 'contribution_approved',
        targetId: contrib.id,
        targetType: 'contribution',
        targetName: 'INR ${contrib.amount.toStringAsFixed(0)}',
        note: receiptNote,
      );
      Get.snackbar('Approved', 'Contribution approved.',
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

  Future<void> declineContribution(
      ContributionModel contrib, String note) async {
    final auth = Get.find<AuthController>();
    isLoading.value = true;
    try {
      await _db.collection('contributions').doc(contrib.id).update({
        'status': 'declined',
        'resolvedAt': Timestamp.now(),
        'resolvedBy': auth.uid,
        'receiptNote': note,
      });
      await ActivityLogService.log(
        action: 'contribution_declined',
        targetId: contrib.id,
        targetType: 'contribution',
        targetName: 'INR ${contrib.amount.toStringAsFixed(0)}',
        note: note,
      );
      Get.snackbar('Declined', 'Contribution declined.',
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

  Future<void> raiseGroupRequest(
      {required List<ContributionModel> contributions,
      required String leaderId}) async {
    final auth = Get.find<AuthController>();
    final totalAmount =
        contributions.fold<double>(0, (sum, c) => sum + c.amount);
    final contribIds = contributions.map((c) => c.id).toList();
    isLoading.value = true;
    try {
      final ref = await _db.collection('group_requests').add({
        'supervisorId': auth.uid,
        'leaderId': leaderId,
        'totalAmount': totalAmount,
        'contribIds': contribIds,
        'status': 'pending_leader',
        'raisedAt': Timestamp.now(),
      });
      await ActivityLogService.log(
        action: 'group_request_raised',
        targetId: ref.id,
        targetType: 'group_request',
        targetName:
            'INR ${totalAmount.toStringAsFixed(0)} (${contribIds.length} items)',
      );
      selectedContribIds.clear();
      Get.snackbar('Sent', 'Group request sent to Leader.',
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

  Future<void> approveGroupRequest(GroupRequestModel req) async {
    final auth = Get.find<AuthController>();
    isLoading.value = true;
    try {
      await _db.collection('group_requests').doc(req.id).update({
        'status': 'approved',
        'resolvedAt': Timestamp.now(),
        'resolvedBy': auth.uid,
      });
      await ActivityLogService.log(
        action: 'group_request_approved',
        targetId: req.id,
        targetType: 'group_request',
        targetName: 'INR ${req.totalAmount.toStringAsFixed(0)}',
      );
      Get.snackbar('Approved', 'Group request approved.',
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

  Future<void> declineGroupRequest(GroupRequestModel req, String note) async {
    final auth = Get.find<AuthController>();
    isLoading.value = true;
    try {
      await _db.collection('group_requests').doc(req.id).update({
        'status': 'declined',
        'resolvedAt': Timestamp.now(),
        'resolvedBy': auth.uid,
        'note': note,
      });
      await ActivityLogService.log(
        action: 'group_request_declined',
        targetId: req.id,
        targetType: 'group_request',
        targetName: 'INR ${req.totalAmount.toStringAsFixed(0)}',
        note: note,
      );
      Get.snackbar('Declined', 'Group request declined.',
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

  Future<void> loadFinancialData() async {
    hasLoadedFinancial.value = false;
    try {
      // Calculate total funds from approved contributions
      final approvedSnapshot = await _db
          .collection('contributions')
          .where('status', isEqualTo: 'approved')
          .get();

      double funds = 0.0;
      for (var doc in approvedSnapshot.docs) {
        final amount = (doc.data()['amount'] is int)
            ? (doc.data()['amount'] as int).toDouble()
            : (doc.data()['amount'] ?? 0.0) as double;
        funds += amount;
      }
      totalFunds.value = funds;

      // Load expense data (mock data for now - in real app, this would come from expenses collection)
      tripCosts.value = funds * 0.35; // 35% of funds for trips
      otherExpenses.value = funds * 0.15; // 15% for other expenses
      totalExpenses.value = tripCosts.value + otherExpenses.value;
      currentBalance.value = funds - totalExpenses.value;

      // Generate sample recent transactions
      recentTransactions.value = [
        {
          'date': '2024-01-15',
          'description': 'Trip to Mumbai',
          'amount': 5000.0,
          'type': 'expense'
        },
        {
          'date': '2024-01-14',
          'description': 'Member Contribution',
          'amount': 2000.0,
          'type': 'income'
        },
        {
          'date': '2024-01-13',
          'description': 'Food Supplies',
          'amount': 1500.0,
          'type': 'expense'
        },
        {
          'date': '2024-01-12',
          'description': 'Member Contribution',
          'amount': 3000.0,
          'type': 'income'
        },
        {
          'date': '2024-01-11',
          'description': 'Transport Fuel',
          'amount': 2500.0,
          'type': 'expense'
        },
      ];

      // Generate expense breakdown
      expenseBreakdown.value = [
        {
          'category': 'Transport',
          'amount': tripCosts.value * 0.6,
          'percentage': 60
        },
        {
          'category': 'Food',
          'amount': tripCosts.value * 0.25,
          'percentage': 25
        },
        {
          'category': 'Accommodation',
          'amount': tripCosts.value * 0.15,
          'percentage': 15
        },
        {'category': 'Other', 'amount': otherExpenses.value, 'percentage': 100},
      ];

      hasLoadedFinancial.value = true;
    } catch (e) {
      hasLoadedFinancial.value =
          true; // Set to true even on error to avoid infinite loading
      Get.snackbar('Error', 'Failed to load financial data: $e',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
