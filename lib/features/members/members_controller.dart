import 'package:get/get.dart';
import '../../core/models/user_model.dart';
import '../../core/services/firestore_service.dart';

class MembersController extends GetxController {
  final RxList<UserModel> allMembers = <UserModel>[].obs;
  final RxList<UserModel> filtered = <UserModel>[].obs;
  final RxString searchQuery = ''.obs;
  final RxString roleFilter = 'all'.obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _listenMembers();
    debounce(searchQuery, (_) => _applyFilters(),
        time: const Duration(milliseconds: 300));
    ever(roleFilter, (_) => _applyFilters());
  }

  void _listenMembers() {
    FirestoreService.users.snapshots().listen((snap) {
      allMembers.value =
          snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
      _applyFilters();
      isLoading.value = false;
    });
  }

  void _applyFilters() {
    var list = allMembers.toList();
    if (roleFilter.value != 'all') {
      list = list.where((m) {
        if (roleFilter.value == 'leader') {
          return m.isLeader;
        } else if (roleFilter.value == 'supervisor') {
          return m.isSupervisor;
        } else {
          return m.isMember;
        }
      }).toList();
    }
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      list = list
          .where((m) =>
              m.fullName.toLowerCase().contains(q) ||
              m.email.toLowerCase().contains(q))
          .toList();
    }
    filtered.value = list;
  }

  void setSearch(String val) => searchQuery.value = val;
  void setRoleFilter(String role) => roleFilter.value = role;
}
