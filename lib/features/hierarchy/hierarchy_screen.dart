import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/controllers/hierarchy_controller.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/models/hierarchy_model.dart';
import '../../core/widgets/glass_card.dart';
import 'add_member_screen.dart';

class HierarchyScreen extends StatelessWidget {
  const HierarchyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(HierarchyController());
    final auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Hierarchy Tree',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Gender switcher
          Obx(() => Row(
            children: [
              _GenderButton(
                gender: Gender.male,
                isSelected: ctrl.currentGender == Gender.male,
                onTap: () => ctrl.switchGender(Gender.male),
              ),
              const SizedBox(width: 8),
              _GenderButton(
                gender: Gender.female,
                isSelected: ctrl.currentGender == Gender.female,
                onTap: () => ctrl.switchGender(Gender.female),
              ),
              const SizedBox(width: 16),
            ],
          )),
          // Admin add button
          if (auth.isSupervisorOrLeader)
            IconButton(
              onPressed: () => Get.to(() => const AddMemberScreen()),
              icon: const FaIcon(
                FontAwesomeIcons.userPlus,
                color: Color(0xFF059669),
              ),
            ),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF059669)),
          );
        }

        if (ctrl.error.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.triangleExclamation,
                  color: Colors.red.shade400,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  ctrl.error,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: ctrl.loadHierarchy,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final tree = ctrl.getUserViewableTree();
        if (tree == null || tree.nodes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.sitemap,
                  color: Colors.white24,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'No hierarchy data available',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: ctrl.loadHierarchy,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics
                _buildStatistics(tree),
                const SizedBox(height: 24),
                
                // Hierarchy tree
                _buildHierarchyTree(tree),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatistics(HierarchyTree tree) {
    final stats = tree.getRoleStatistics();
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      opacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                tree.gender == Gender.male 
                    ? FontAwesomeIcons.person 
                    : FontAwesomeIcons.personDress,
                color: tree.gender == Gender.male 
                    ? const Color(0xFF4ECDC4) 
                    : const Color(0xFFE91E63),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                '${tree.gender.displayName} Hierarchy',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669),
                ),
              ),
              const Spacer(),
              Text(
                'Total: ${tree.totalActiveMembers}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: stats.entries.map((entry) {
              return _RoleStat(
                role: entry.key,
                count: entry.value,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchyTree(HierarchyTree tree) {
    final roots = tree.roots;
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      opacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Organization Structure',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 16),
          
          // Build tree from roots
          ...roots.map((root) => _buildTreeNode(tree, root, 0)),
        ],
      ),
    );
  }

  Widget _buildTreeNode(HierarchyTree tree, HierarchyNode node, int level) {
    final children = tree.getChildren(node.id);
    final hasChildren = children.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Node card
        Container(
          margin: EdgeInsets.only(left: level * 24.0),
          child: _NodeCard(
            node: node,
            hasChildren: hasChildren,
            level: level,
          ),
        ),
        
        // Children
        if (hasChildren)
          ...children.map((child) => _buildTreeNode(tree, child, level + 1)),
      ],
    );
  }
}

class _GenderButton extends StatelessWidget {
  final Gender gender;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderButton({
    required this.gender,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? (gender == Gender.male 
                  ? const Color(0xFF4ECDC4).withOpacity(0.2)
                  : const Color(0xFFE91E63).withOpacity(0.2))
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? (gender == Gender.male 
                    ? const Color(0xFF4ECDC4)
                    : const Color(0xFFE91E63))
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              gender == Gender.male 
                  ? FontAwesomeIcons.person 
                  : FontAwesomeIcons.personDress,
              size: 14,
              color: isSelected 
                  ? (gender == Gender.male 
                      ? const Color(0xFF4ECDC4)
                      : const Color(0xFFE91E63))
                  : Colors.white54,
            ),
            const SizedBox(width: 6),
            Text(
              gender.displayName,
              style: TextStyle(
                fontSize: 12,
                color: isSelected 
                    ? (gender == Gender.male 
                        ? const Color(0xFF4ECDC4)
                        : const Color(0xFFE91E63))
                    : Colors.white54,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleStat extends StatelessWidget {
  final HierarchyRole role;
  final int count;

  const _RoleStat({
    required this.role,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getRoleColor(role);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            role.displayName,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(HierarchyRole role) {
    switch (role) {
      case HierarchyRole.leader:
        return const Color(0xFFFF6B6B);
      case HierarchyRole.coreTeamLeader:
        return const Color(0xFF4ECDC4);
      case HierarchyRole.captain:
        return const Color(0xFF45B7D1);
      case HierarchyRole.supervisor:
        return const Color(0xFF96CEB4);
      case HierarchyRole.monitor:
        return const Color(0xFFFFEAA7);
      case HierarchyRole.member:
        return const Color(0xFFDFE6E9);
    }
  }
}

class _NodeCard extends StatelessWidget {
  final HierarchyNode node;
  final bool hasChildren;
  final int level;

  const _NodeCard({
    required this.node,
    required this.hasChildren,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(node.roleColor.replaceFirst('#', '0xFF')));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Expand/collapse icon
          if (hasChildren)
            FaIcon(
              FontAwesomeIcons.chevronDown,
              color: color.withOpacity(0.6),
              size: 12,
            )
          else
            const SizedBox(width: 12),
          
          const SizedBox(width: 8),
          
          // Role icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(
              _getRoleIcon(node.role),
              color: color,
              size: 16,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Node info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  node.role.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          
          // Contact info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (node.phone.isNotEmpty)
                Text(
                  node.phone,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              if (node.email.isNotEmpty)
                Text(
                  node.email,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(HierarchyRole role) {
    switch (role) {
      case HierarchyRole.leader:
        return FontAwesomeIcons.crown;
      case HierarchyRole.coreTeamLeader:
        return FontAwesomeIcons.userTie;
      case HierarchyRole.captain:
        return FontAwesomeIcons.star;
      case HierarchyRole.supervisor:
        return FontAwesomeIcons.userShield;
      case HierarchyRole.monitor:
        return FontAwesomeIcons.eye;
      case HierarchyRole.member:
        return FontAwesomeIcons.user;
    }
  }
}
