import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import '../models/hierarchy_model.dart';
import 'auth_controller.dart';

class HierarchyController extends GetxController {
  static HierarchyController get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Rx<Map<String, HierarchyNode>> _allNodes = Rx({});
  final Rx<HierarchyTree?> _maleTree = Rx(null);
  final Rx<HierarchyTree?> _femaleTree = Rx(null);
  final Rx<Gender?> _currentGender = Rx(Gender.male);
  final Rx<bool> _isLoading = Rx(false);
  final Rx<String> _error = Rx('');

  // Getters
  Map<String, HierarchyNode> get allNodes => _allNodes.value;
  HierarchyTree? get maleTree => _maleTree.value;
  HierarchyTree? get femaleTree => _femaleTree.value;
  Gender? get currentGender => _currentGender.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;

  // Current tree based on selected gender
  HierarchyTree? get currentTree {
    switch (_currentGender.value) {
      case Gender.male:
        return _maleTree.value;
      case Gender.female:
        return _femaleTree.value;
      default:
        return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadHierarchy();
  }

  // Load entire hierarchy from Firestore
  Future<void> loadHierarchy() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final snapshot = await _firestore
          .collection('hierarchy')
          .where('isActive', isEqualTo: true)
          .get();

      final nodes = <String, HierarchyNode>{};
      for (final doc in snapshot.docs) {
        final node = HierarchyNode.fromFirestore(doc);
        nodes[node.id] = node;
      }

      _allNodes.value = nodes;
      _buildTrees();
    } catch (e) {
      _error.value = 'Failed to load hierarchy: $e';
      Get.snackbar('Error', 'Failed to load hierarchy structure');
    } finally {
      _isLoading.value = false;
    }
  }

  // Build male and female trees
  void _buildTrees() {
    final allNodeList = _allNodes.value.values.toList();
    _maleTree.value = HierarchyTree.fromNodes(allNodeList, Gender.male);
    _femaleTree.value = HierarchyTree.fromNodes(allNodeList, Gender.female);
  }

  // Switch between male/female hierarchy view
  void switchGender(Gender gender) {
    _currentGender.value = gender;
  }

  // Add new node to hierarchy
  Future<bool> addNode({
    required String name,
    required String email,
    required String phone,
    required HierarchyRole role,
    required Gender gender,
    String? parentId,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      // Validate if parent can have children
      if (parentId != null) {
        final parent = _allNodes.value[parentId];
        if (parent == null) {
          _error.value = 'Parent not found';
          return false;
        }
        if (!parent.canHaveChildren) {
          _error.value = 'This parent cannot have children';
          return false;
        }
        if (parent.gender != gender) {
          _error.value = 'Parent and child must be same gender';
          return false;
        }
      }

      // Check monitor member limit
      if (role == HierarchyRole.monitor && parentId != null) {
        final existingChildren = currentTree?.getChildren(parentId) ?? [];
        final memberCount = existingChildren
            .where((child) => child.role == HierarchyRole.member)
            .length;
        if (memberCount >= 10) {
          _error.value = 'Monitor already has maximum members (10)';
          return false;
        }
      }

      final newNode = HierarchyNode(
        id: _firestore.collection('hierarchy').doc().id,
        name: name,
        email: email,
        phone: phone,
        role: role,
        gender: gender,
        parentId: parentId,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('hierarchy')
          .doc(newNode.id)
          .set(newNode.toFirestore());

      // Update local cache
      final updatedNodes = Map<String, HierarchyNode>.from(_allNodes.value);
      updatedNodes[newNode.id] = newNode;
      _allNodes.value = updatedNodes;
      _buildTrees();

      Get.snackbar('Success', '$name added to hierarchy');
      return true;
    } catch (e) {
      _error.value = 'Failed to add node: $e';
      Get.snackbar('Error', 'Failed to add member to hierarchy');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Update existing node
  Future<bool> updateNode({
    required String nodeId,
    String? name,
    String? email,
    String? phone,
    HierarchyRole? role,
    String? parentId,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final currentNode = _allNodes.value[nodeId];
      if (currentNode == null) {
        _error.value = 'Node not found';
        return false;
      }

      // Validate parent change
      if (parentId != null && parentId != currentNode.parentId) {
        final parent = _allNodes.value[parentId];
        if (parent == null) {
          _error.value = 'Parent not found';
          return false;
        }
        if (!parent.canHaveChildren) {
          _error.value = 'This parent cannot have children';
          return false;
        }
        if (parent.gender != currentNode.gender) {
          _error.value = 'Parent and child must be same gender';
          return false;
        }

        // Check if this would create a cycle
        if (_wouldCreateCycle(nodeId, parentId)) {
          _error.value = 'This would create a circular hierarchy';
          return false;
        }
      }

      final updatedNode = currentNode.copyWith(
        name: name,
        email: email,
        phone: phone,
        role: role,
        parentId: parentId,
        lastActive: DateTime.now(),
      );

      await _firestore
          .collection('hierarchy')
          .doc(nodeId)
          .update(updatedNode.toFirestore());

      // Update local cache
      final updatedNodes = Map<String, HierarchyNode>.from(_allNodes.value);
      updatedNodes[nodeId] = updatedNode;
      _allNodes.value = updatedNodes;
      _buildTrees();

      Get.snackbar('Success', 'Hierarchy updated successfully');
      return true;
    } catch (e) {
      _error.value = 'Failed to update node: $e';
      Get.snackbar('Error', 'Failed to update hierarchy');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Remove node (deactivate)
  Future<bool> removeNode(String nodeId) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final node = _allNodes.value[nodeId];
      if (node == null) {
        _error.value = 'Node not found';
        return false;
      }

      // Check if node has children
      final tree =
          node.gender == Gender.male ? _maleTree.value : _femaleTree.value;
      final children = tree?.getChildren(nodeId) ?? [];
      if (children.isNotEmpty) {
        _error.value =
            'Cannot remove node with children. Remove children first.';
        return false;
      }

      await _firestore
          .collection('hierarchy')
          .doc(nodeId)
          .update({'isActive': false, 'lastActive': DateTime.now()});

      // Update local cache
      final updatedNodes = Map<String, HierarchyNode>.from(_allNodes.value);
      updatedNodes[nodeId] = node.copyWith(isActive: false);
      _allNodes.value = updatedNodes;
      _buildTrees();

      Get.snackbar('Success', 'Node removed from hierarchy');
      return true;
    } catch (e) {
      _error.value = 'Failed to remove node: $e';
      Get.snackbar('Error', 'Failed to remove from hierarchy');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Check if adding edge would create a cycle
  bool _wouldCreateCycle(String nodeId, String newParentId) {
    // Simple cycle detection: check if newParentId is a descendant of nodeId
    final tree = _allNodes.value[nodeId]?.gender == Gender.male
        ? _maleTree.value
        : _femaleTree.value;

    if (tree == null) return false;

    final descendants = tree.getAllDescendants(nodeId);
    return descendants.any((descendant) => descendant.id == newParentId);
  }

  // Get viewable tree for current user based on their role
  HierarchyTree? getUserViewableTree() {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn.value) return null;

    final userNode = _allNodes.value.values.firstWhereOrNull(
      (node) => node.email == auth.currentUser.value?.email,
    );

    if (userNode == null) return null;

    // Admins see full tree
    if (auth.isLeader) {
      return userNode.gender == Gender.male
          ? _maleTree.value
          : _femaleTree.value;
    }

    // Other roles see only their subtree
    return currentTree?.getSubtree(userNode.id);
  }

  // Get user's role in hierarchy
  HierarchyRole? getUserRole() {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn.value) return null;

    final userNode = _allNodes.value.values.firstWhereOrNull(
      (node) => node.email == auth.currentUser.value?.email,
    );

    return userNode?.role;
  }

  // Get available parents for a given role and gender
  List<HierarchyNode> getAvailableParents(HierarchyRole role, Gender gender) {
    final tree = gender == Gender.male ? _maleTree.value : _femaleTree.value;
    if (tree == null) return [];

    return tree.nodes.values.where((node) {
      if (!node.canHaveChildren) return false;
      if (node.gender != gender) return false;

      // Check hierarchy level compatibility
      return node.role.level < role.level;
    }).toList();
  }

  // Validate entire hierarchy
  List<String> validateHierarchy() {
    final errors = <String>[];

    final maleErrors = _maleTree.value?.validateStructure() ?? [];
    final femaleErrors = _femaleTree.value?.validateStructure() ?? [];

    errors.addAll(maleErrors);
    errors.addAll(femaleErrors);

    return errors;
  }

  // Get hierarchy statistics
  Map<String, dynamic> getStatistics() {
    final maleStats = _maleTree.value?.getRoleStatistics() ?? {};
    final femaleStats = _femaleTree.value?.getRoleStatistics() ?? {};

    return {
      'totalMale': _maleTree.value?.totalActiveMembers ?? 0,
      'totalFemale': _femaleTree.value?.totalActiveMembers ?? 0,
      'total': (_maleTree.value?.totalActiveMembers ?? 0) +
          (_femaleTree.value?.totalActiveMembers ?? 0),
      'maleByRole':
          maleStats.map((key, value) => MapEntry(key.displayName, value)),
      'femaleByRole':
          femaleStats.map((key, value) => MapEntry(key.displayName, value)),
    };
  }

  // Clear error
  void clearError() {
    _error.value = '';
  }
}
