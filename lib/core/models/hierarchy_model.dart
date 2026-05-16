import 'package:cloud_firestore/cloud_firestore.dart';

enum HierarchyRole {
  leader('Leader', 0),
  coreTeamLeader('Core Team Leader', 1),
  captain('Captain', 2),
  supervisor('Supervisor', 3),
  monitor('Monitor', 4),
  member('Member', 5);

  const HierarchyRole(this.displayName, this.level);
  final String displayName;
  final int level;

  static HierarchyRole fromString(String value) {
    return HierarchyRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => HierarchyRole.member,
    );
  }
}

enum Gender {
  male('Male'),
  female('Female');

  const Gender(this.displayName);
  final String displayName;

  static Gender fromString(String value) {
    return Gender.values.firstWhere(
      (gender) => gender.name == value,
      orElse: () => Gender.male,
    );
  }
}

class HierarchyNode {
  final String id;
  final String name;
  final String email;
  final String phone;
  final HierarchyRole role;
  final Gender gender;
  final String? parentId;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime? lastActive;
  final bool isActive;

  HierarchyNode({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.gender,
    this.parentId,
    this.memberIds = const [],
    required this.createdAt,
    this.lastActive,
    this.isActive = true,
  });

  factory HierarchyNode.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HierarchyNode(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: HierarchyRole.fromString(data['role'] ?? 'member'),
      gender: Gender.fromString(data['gender'] ?? 'male'),
      parentId: data['parentId'],
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActive: data['lastActive'] != null
          ? (data['lastActive'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'gender': gender.name,
      'parentId': parentId,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'isActive': isActive,
    };
  }

  HierarchyNode copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    HierarchyRole? role,
    Gender? gender,
    String? parentId,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? isActive,
  }) {
    return HierarchyNode(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      parentId: parentId ?? this.parentId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isActive: isActive ?? this.isActive,
    );
  }

  // Get the maximum number of members this role can have
  int get maxMembers {
    switch (role) {
      case HierarchyRole.monitor:
        return 10;
      case HierarchyRole.supervisor:
        return 11; // 1 monitor + 10 members
      case HierarchyRole.captain:
        return 22; // 2 supervisors + their teams
      case HierarchyRole.coreTeamLeader:
        return 44; // 2 captains + their teams
      case HierarchyRole.leader:
        return 88; // 2 core team leaders + their teams
      case HierarchyRole.member:
        return 0;
    }
  }

  // Get the level in hierarchy (0 = top, 5 = bottom)
  int get level {
    switch (role) {
      case HierarchyRole.leader:
        return 0;
      case HierarchyRole.coreTeamLeader:
        return 1;
      case HierarchyRole.captain:
        return 2;
      case HierarchyRole.supervisor:
        return 3;
      case HierarchyRole.monitor:
        return 4;
      case HierarchyRole.member:
        return 5;
    }
  }

  // Check if this node can have children
  bool get canHaveChildren {
    return role != HierarchyRole.member;
  }

  // Get display color based on role
  String get roleColor {
    switch (role) {
      case HierarchyRole.leader:
        return '#FF6B6B'; // Red
      case HierarchyRole.coreTeamLeader:
        return '#4ECDC4'; // Teal
      case HierarchyRole.captain:
        return '#45B7D1'; // Blue
      case HierarchyRole.supervisor:
        return '#96CEB4'; // Green
      case HierarchyRole.monitor:
        return '#FFEAA7'; // Yellow
      case HierarchyRole.member:
        return '#DFE6E9'; // Light gray
    }
  }
}

class HierarchyTree {
  final Map<String, HierarchyNode> nodes;
  final Map<String, List<String>> childrenMap;
  final Gender gender;

  HierarchyTree({
    required this.nodes,
    required this.childrenMap,
    required this.gender,
  });

  factory HierarchyTree.fromNodes(List<HierarchyNode> allNodes, Gender gender) {
    final nodes = <String, HierarchyNode>{};
    final childrenMap = <String, List<String>>{};

    // Filter nodes by gender
    final genderNodes =
        allNodes.where((node) => node.gender == gender).toList();

    // Build nodes map
    for (final node in genderNodes) {
      nodes[node.id] = node;
    }

    // Build children map
    for (final node in genderNodes) {
      if (node.parentId != null && nodes.containsKey(node.parentId)) {
        childrenMap[node.parentId!] ??= [];
        childrenMap[node.parentId]!.add(node.id);
      }
    }

    return HierarchyTree(
      nodes: nodes,
      childrenMap: childrenMap,
      gender: gender,
    );
  }

  // Get root nodes (leaders)
  List<HierarchyNode> get roots {
    return nodes.values
        .where((node) => node.role == HierarchyRole.leader)
        .toList();
  }

  // Get children of a node
  List<HierarchyNode> getChildren(String parentId) {
    final childIds = childrenMap[parentId] ?? [];
    return childIds
        .map((id) => nodes[id]!)
        .where((node) => node.isActive)
        .toList();
  }

  // Get parent of a node
  HierarchyNode? getParent(String nodeId) {
    final node = nodes[nodeId];
    if (node?.parentId == null) return null;
    return nodes[node!.parentId];
  }

  // Get all descendants of a node
  List<HierarchyNode> getAllDescendants(String nodeId) {
    final descendants = <HierarchyNode>[];
    final children = getChildren(nodeId);

    for (final child in children) {
      descendants.add(child);
      descendants.addAll(getAllDescendants(child.id));
    }

    return descendants;
  }

  // Get subtree for a specific node (for role-based viewing)
  HierarchyTree getSubtree(String nodeId) {
    final node = nodes[nodeId];
    if (node == null) {
      return HierarchyTree(nodes: {}, childrenMap: {}, gender: gender);
    }

    final subtreeNodes = <String, HierarchyNode>{};
    final subtreeChildren = <String, List<String>>{};

    // Add the root node
    subtreeNodes[node.id] = node;

    // Add all descendants
    final descendants = getAllDescendants(nodeId);
    for (final descendant in descendants) {
      subtreeNodes[descendant.id] = descendant;

      // Build children relationships
      if (descendant.parentId != null &&
          subtreeNodes.containsKey(descendant.parentId)) {
        subtreeChildren[descendant.parentId!] ??= [];
        subtreeChildren[descendant.parentId]!.add(descendant.id);
      }
    }

    return HierarchyTree(
      nodes: subtreeNodes,
      childrenMap: subtreeChildren,
      gender: gender,
    );
  }

  // Validate hierarchy structure
  List<String> validateStructure() {
    final errors = <String>[];

    for (final node in nodes.values) {
      // Check monitor member limit
      if (node.role == HierarchyRole.monitor) {
        final members = getChildren(node.id)
            .where((child) => child.role == HierarchyRole.member)
            .toList();
        if (members.length > 10) {
          errors.add(
              'Monitor ${node.name} has ${members.length} members (max: 10)');
        }
      }

      // Check if parent exists and is appropriate
      if (node.parentId != null) {
        final parent = nodes[node.parentId];
        if (parent == null) {
          errors.add('Node ${node.name} has non-existent parent');
        } else if (!parent.canHaveChildren) {
          errors.add(
              'Node ${node.name} has parent ${parent.name} who cannot have children');
        } else if (parent.level >= node.level) {
          errors.add(
              'Invalid hierarchy: ${parent.name} (${parent.role}) cannot be parent of ${node.name} (${node.role})');
        }
      }
    }

    return errors;
  }

  // Get statistics
  Map<HierarchyRole, int> getRoleStatistics() {
    final stats = <HierarchyRole, int>{};
    for (final role in HierarchyRole.values) {
      stats[role] = 0;
    }

    for (final node in nodes.values) {
      if (node.isActive) {
        stats[node.role] = (stats[node.role] ?? 0) + 1;
      }
    }

    return stats;
  }

  int get totalActiveMembers =>
      nodes.values.where((node) => node.isActive).length;
}
