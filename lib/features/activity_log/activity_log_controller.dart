import 'package:get/get.dart';
import '../../core/models/activity_log_model.dart';
import '../../core/services/firestore_service.dart';

class ActivityLogController extends GetxController {
  final RxList<ActivityLogModel> logs = <ActivityLogModel>[].obs;
  final RxString actionFilter = 'all'.obs;
  final RxBool isLoading = true.obs;

  final List<String> filterOptions = [
    'all',
    'contribution_raised',
    'contribution_approved',
    'contribution_declined',
    'group_request_raised',
    'group_request_approved',
    'group_request_declined',
    'transfer_raised',
    'transfer_leader_approved',
    'transfer_leader_declined',
    'member_role_changed',
    'member_team_moved',
    'event_created',
    'attendance_marked',
    'announcement_published',
  ];

  @override
  void onInit() {
    super.onInit();
    _listenLogs();
    ever(actionFilter, (_) => _listenLogs());
  }

  void _listenLogs() {
    isLoading.value = true;
    FirestoreService.streamActivityLogs(limit: 200).listen((list) {
      if (actionFilter.value == 'all') {
        logs.value = list;
      } else {
        logs.value = list
            .where((l) => l.action == actionFilter.value)
            .toList();
      }
      isLoading.value = false;
    });
  }

  void setFilter(String filter) => actionFilter.value = filter;

  String filterLabel(String action) {
    const labels = {
      'all': 'All Actions',
      'contribution_raised': 'Contributions Raised',
      'contribution_approved': 'Contributions Approved',
      'contribution_declined': 'Contributions Declined',
      'group_request_raised': 'Group Requests Raised',
      'group_request_approved': 'Group Requests Approved',
      'group_request_declined': 'Group Requests Declined',
      'transfer_raised': 'Transfers Raised',
      'transfer_leader_approved': 'Transfers Approved',
      'transfer_leader_declined': 'Transfers Declined',
      'member_role_changed': 'Role Changes',
      'member_team_moved': 'Team Moves',
      'event_created': 'Events Created',
      'attendance_marked': 'Attendance Marked',
      'announcement_published': 'Announcements',
    };
    return labels[action] ?? action;
  }
}
