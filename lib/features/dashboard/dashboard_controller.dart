import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../core/controllers/auth_controller.dart';

class DashboardController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxInt memberCount = 0.obs;
  final RxInt teamCount = 0.obs;
  final RxInt eventCount = 0.obs;
  final RxInt pendingGroupRequests = 0.obs;
  final RxInt pendingTransfers = 0.obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadStats();
  }

  Future<void> loadStats() async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      final futures = <Future>[];

      // Try to load stats with error handling for permission denied
      try {
        futures.add(_db.collection('users').count().get());
      } catch (e) {
        // Skip this stat if permission denied
        memberCount.value = 0;
      }

      try {
        futures.add(_db.collection('teams').count().get());
      } catch (e) {
        // Skip this stat if permission denied
        teamCount.value = 0;
      }

      try {
        futures.add(_db.collection('events').count().get());
      } catch (e) {
        // Skip this stat if permission denied
        eventCount.value = 0;
      }

      if (auth.isSupervisorOrLeader) {
        try {
          futures.add(
            _db
                .collection('group_requests')
                .where('status', isEqualTo: 'pending_leader')
                .count()
                .get(),
          );
        } catch (e) {
          // Skip this stat if permission denied
          pendingGroupRequests.value = 0;
        }
        try {
          futures.add(
            _db
                .collection('transfer_requests')
                .where('status', isEqualTo: 'pending_supervisor')
                .count()
                .get(),
          );
        } catch (e) {
          // Skip this stat if permission denied
          pendingTransfers.value = 0;
        }
      }

      final results = await Future.wait(futures);
      memberCount.value = results[0].count ?? 0;
      teamCount.value = results[1].count ?? 0;
      eventCount.value = results[2].count ?? 0;

      if (auth.isSupervisorOrLeader && results.length >= 5) {
        pendingGroupRequests.value = results[3].count ?? 0;
        pendingTransfers.value = results[4].count ?? 0;
      }
    } catch (e) {
      memberCount.value = 0;
      teamCount.value = 0;
      eventCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }
}
