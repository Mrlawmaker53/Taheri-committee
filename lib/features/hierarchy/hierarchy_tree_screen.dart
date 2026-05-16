import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/controllers/theme_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/models/hierarchy_model.dart';
import '../../core/widgets/glass_card.dart';
import 'hierarchy_controller.dart';

class HierarchyTreeScreen extends StatelessWidget {
  const HierarchyTreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(HierarchyController());
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Hierarchy'),
        backgroundColor: isDark ? AppTokens.darkBg : AppTokens.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(context),
            icon: const FaIcon(
              FontAwesomeIcons.filter,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (!ctrl.hasLoaded.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (ctrl.hierarchyNodes.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _buildHierarchyTree(ctrl, isDark),
        );
      }),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.sitemap,
            size: 64,
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No Hierarchy Data',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Team hierarchy will appear here',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchyTree(HierarchyController ctrl, bool isDark) {
    final rootNodes = ctrl.getRootNodes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary cards
        _buildSummaryCards(ctrl, isDark),
        const SizedBox(height: 24),

        // Hierarchy tree
        ...rootNodes.map((node) => _buildTreeNode(node, ctrl, 0, isDark)),
      ],
    );
  }

  Widget _buildSummaryCards(HierarchyController ctrl, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: isDark
              ? GlassCard(
                  padding: const EdgeInsets.all(16),
                  opacity: 0.08,
                  child: _buildSummaryItem(
                    'Total Members',
                    '${ctrl.totalMembers}',
                    FontAwesomeIcons.users,
                    const Color(0xFF059669),
                    isDark,
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildSummaryItem(
                    'Total Members',
                    '${ctrl.totalMembers}',
                    FontAwesomeIcons.users,
                    const Color(0xFF059669),
                    isDark,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: isDark
              ? GlassCard(
                  padding: const EdgeInsets.all(16),
                  opacity: 0.08,
                  child: _buildSummaryItem(
                    'Teams',
                    '${ctrl.totalTeams}',
                    FontAwesomeIcons.peopleGroup,
                    const Color(0xFFD97706),
                    isDark,
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildSummaryItem(
                    'Teams',
                    '${ctrl.totalTeams}',
                    FontAwesomeIcons.peopleGroup,
                    const Color(0xFFD97706),
                    isDark,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: isDark
              ? GlassCard(
                  padding: const EdgeInsets.all(16),
                  opacity: 0.08,
                  child: _buildSummaryItem(
                    'Active',
                    '${ctrl.activeMembers}',
                    FontAwesomeIcons.userCheck,
                    AppTokens.success,
                    isDark,
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTokens.darkCard : AppTokens.primaryLight,
                    borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    border:
                        Border.all(color: AppTokens.primary.withOpacity(0.2)),
                    boxShadow: AppTokens.cardShadow,
                  ),
                  child: _buildSummaryItem(
                    'Active',
                    '${ctrl.activeMembers}',
                    FontAwesomeIcons.userCheck,
                    AppTokens.success,
                    isDark,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        FaIcon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTreeNode(
      HierarchyNode node, HierarchyController ctrl, int level, bool isDark) {
    final children = ctrl.getChildren(node.id);
    final isExpanded = ctrl.expandedNodes.contains(node.id);
    final hasChildren = children.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          // Node card
          _buildNodeCard(node, ctrl, level, isExpanded, hasChildren, isDark),

          // Children (if expanded)
          if (hasChildren && isExpanded) ...[
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(left: 32.0 + (level * 16)),
              child: Column(
                children: children
                    .map((child) =>
                        _buildTreeNode(child, ctrl, level + 1, isDark))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNodeCard(
    HierarchyNode node,
    HierarchyController ctrl,
    int level,
    bool isExpanded,
    bool hasChildren,
    bool isDark,
  ) {
    final roleColor = _getRoleColor(node.role);

    return isDark
        ? GlassCard(
            padding: const EdgeInsets.all(16),
            opacity: 0.08,
            child: _buildNodeCardContent(
                node, ctrl, level, isExpanded, hasChildren, roleColor, isDark),
          )
        : Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTokens.darkCard : AppTokens.surfaceWhite,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              border: Border.all(color: AppTokens.borderLight, width: 0.5),
              boxShadow: AppTokens.cardShadow,
            ),
            child: _buildNodeCardContent(
                node, ctrl, level, isExpanded, hasChildren, roleColor, isDark),
          );
  }

  Widget _buildNodeCardContent(
    HierarchyNode node,
    HierarchyController ctrl,
    int level,
    bool isExpanded,
    bool hasChildren,
    Color roleColor,
    bool isDark,
  ) {
    return Row(
      children: [
        // Expand/Collapse button
        if (hasChildren)
          GestureDetector(
            onTap: () => ctrl.toggleNode(node.id),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FaIcon(
                isExpanded
                    ? FontAwesomeIcons.chevronDown
                    : FontAwesomeIcons.chevronRight,
                color: roleColor,
                size: 12,
              ),
            ),
          )
        else
          const SizedBox(width: 24),

        const SizedBox(width: 12),

        // Avatar with role indicator
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                roleColor.withOpacity(0.3),
                roleColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: roleColor.withOpacity(0.5)),
          ),
          child: Center(
            child: FaIcon(
              _getRoleIcon(node.role),
              color: roleColor,
              size: 20,
            ),
          ),
        ),

        const SizedBox(width: 16),

        // User info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    node.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      node.role.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: roleColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (node.email.isNotEmpty) ...[
                    FaIcon(
                      FontAwesomeIcons.envelope,
                      size: 12,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      node.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (node.phone.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    FaIcon(
                      FontAwesomeIcons.phone,
                      size: 12,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      node.phone,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Status indicator
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: node.isActive ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(HierarchyRole role) {
    switch (role) {
      case HierarchyRole.leader:
        return AppTokens.roleLeader; // red
      case HierarchyRole.coreTeamLeader:
        return AppTokens.info; // purple
      case HierarchyRole.captain:
        return AppTokens.roleSupervisor; // cyan
      case HierarchyRole.supervisor:
        return AppTokens.roleSupervisor; // cyan
      case HierarchyRole.monitor:
        return AppTokens.warning; // orange
      case HierarchyRole.member:
        return AppTokens.roleMember; // green
    }
  }

  IconData _getRoleIcon(HierarchyRole role) {
    switch (role) {
      case HierarchyRole.leader:
        return FontAwesomeIcons.crown;
      case HierarchyRole.coreTeamLeader:
        return FontAwesomeIcons.star;
      case HierarchyRole.captain:
        return FontAwesomeIcons.userShield;
      case HierarchyRole.supervisor:
        return FontAwesomeIcons.userTie;
      case HierarchyRole.monitor:
        return FontAwesomeIcons.clipboardUser;
      case HierarchyRole.member:
        return FontAwesomeIcons.user;
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Hierarchy'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filter options will be implemented here'),
            SizedBox(height: 16),
            // TODO: Add filter options
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
