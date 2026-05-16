import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../core/models/hierarchy_model.dart';

class HierarchyController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxList<HierarchyNode> hierarchyNodes = <HierarchyNode>[].obs;
  final RxSet<String> expandedNodes = <String>{}.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    _listenHierarchy();
  }

  void _listenHierarchy() {
    _db
        .collection('hierarchy')
        .orderBy('level')
        .orderBy('name')
        .snapshots()
        .listen((snap) {
      hierarchyNodes.value =
          snap.docs.map((doc) => HierarchyNode.fromFirestore(doc)).toList();
      hasLoaded.value = true;
    });
  }

  List<HierarchyNode> getRootNodes() {
    return hierarchyNodes
        .where((node) => node.parentId == null || node.parentId!.isEmpty)
        .toList();
  }

  List<HierarchyNode> getChildren(String parentId) {
    return hierarchyNodes.where((node) => node.parentId == parentId).toList();
  }

  HierarchyNode? getNodeById(String id) {
    try {
      return hierarchyNodes.firstWhere((node) => node.id == id);
    } catch (e) {
      return null;
    }
  }

  void toggleNode(String nodeId) {
    if (expandedNodes.contains(nodeId)) {
      expandedNodes.remove(nodeId);
    } else {
      expandedNodes.add(nodeId);
    }
  }

  void expandAll() {
    expandedNodes.addAll(hierarchyNodes.map((node) => node.id));
  }

  void collapseAll() {
    expandedNodes.clear();
  }

  // Statistics
  int get totalMembers => hierarchyNodes.length;

  int get activeMembers => hierarchyNodes.where((node) => node.isActive).length;

  int get totalTeams {
    final leaders = hierarchyNodes
        .where((node) =>
            node.role == HierarchyRole.leader ||
            node.role == HierarchyRole.coreTeamLeader ||
            node.role == HierarchyRole.captain)
        .length;
    return leaders;
  }

  List<HierarchyNode> getNodesByRole(HierarchyRole role) {
    return hierarchyNodes.where((node) => node.role == role).toList();
  }

  List<HierarchyNode> getActiveNodes() {
    return hierarchyNodes.where((node) => node.isActive).toList();
  }

  List<HierarchyNode> getInactiveNodes() {
    return hierarchyNodes.where((node) => !node.isActive).toList();
  }

  Future<void> updateNodeStatus(String nodeId, bool isActive) async {
    try {
      await _db.collection('hierarchy').doc(nodeId).update({
        'isActive': isActive,
        'lastActive': isActive ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status: $e');
    }
  }

  Future<void> addMember({
    required String name,
    required String email,
    required String phone,
    required HierarchyRole role,
    required Gender gender,
    String? parentId,
  }) async {
    try {
      await _db.collection('hierarchy').add({
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'gender': gender.name,
        'parentId': parentId,
        'memberIds': [],
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      Get.snackbar('Success', 'Member added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add member: $e');
    }
  }

  Future<void> removeMember(String nodeId) async {
    try {
      await _db.collection('hierarchy').doc(nodeId).delete();
      Get.snackbar('Success', 'Member removed successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove member: $e');
    }
  }

  Future<void> updateMember({
    required String nodeId,
    String? name,
    String? email,
    String? phone,
    HierarchyRole? role,
    Gender? gender,
    String? parentId,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      if (phone != null) updates['phone'] = phone;
      if (role != null) updates['role'] = role.name;
      if (gender != null) updates['gender'] = gender.name;
      if (parentId != null) updates['parentId'] = parentId;

      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _db.collection('hierarchy').doc(nodeId).update(updates);
      Get.snackbar('Success', 'Member updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update member: $e');
    }
  }

  // Search functionality
  List<HierarchyNode> searchNodes(String query) {
    if (query.isEmpty) return hierarchyNodes;

    final lowerQuery = query.toLowerCase();
    return hierarchyNodes
        .where((node) =>
            node.name.toLowerCase().contains(lowerQuery) ||
            node.email.toLowerCase().contains(lowerQuery) ||
            node.phone.toLowerCase().contains(lowerQuery) ||
            node.role.displayName.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // Export functionality
  String exportToText() {
    final buffer = StringBuffer();
    buffer.writeln('Team Hierarchy Report');
    buffer.writeln('==================');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('');

    for (final node in getRootNodes()) {
      _exportNode(node, buffer, 0);
    }

    return buffer.toString();
  }

  void _exportNode(HierarchyNode node, StringBuffer buffer, int level) {
    final indent = '  ' * level;
    buffer.writeln('$indent${node.name} (${node.role.displayName})');
    buffer.writeln('$indent  Email: ${node.email}');
    buffer.writeln('$indent  Phone: ${node.phone}');
    buffer.writeln('$indent  Status: ${node.isActive ? "Active" : "Inactive"}');
    buffer.writeln('');

    for (final child in getChildren(node.id)) {
      _exportNode(child, buffer, level + 1);
    }
  }
}
