import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/controllers/theme_controller.dart';
import '../../core/widgets/glass_card.dart';
import '../hierarchy/hierarchy_controller.dart';
import '../../core/models/hierarchy_model.dart';

class RoleManagementForm extends StatefulWidget {
  const RoleManagementForm({super.key});

  @override
  State<RoleManagementForm> createState() => _RoleManagementFormState();
}

class _RoleManagementFormState extends State<RoleManagementForm> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HierarchyController>();
    final auth = Get.find<AuthController>();
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Management'),
        actions: [
          IconButton(
            onPressed: () => _showAddMemberDialog(context),
            icon: const FaIcon(FontAwesomeIcons.userPlus),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: isDark
                ? GlassCard(
                    padding: const EdgeInsets.all(16),
                    opacity: 0.08,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search members...',
                        prefixIcon: const FaIcon(FontAwesomeIcons.search,
                            color: Color(0xFF059669)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF059669)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF059669), width: 2),
                        ),
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        // Trigger search update
                        ctrl.searchNodes(value);
                      },
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search members...',
                        prefixIcon: const FaIcon(FontAwesomeIcons.search,
                            color: Color(0xFF059669)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                      ),
                      onChanged: (value) {
                        ctrl.searchNodes(value);
                      },
                    ),
                  ),
          ),

          // Statistics Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total Members', '${ctrl.totalMembers}',
                      FontAwesomeIcons.users, const Color(0xFF059669), isDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                      'Active',
                      '${ctrl.activeMembers}',
                      FontAwesomeIcons.userCheck,
                      const Color(0xFF4CAF50),
                      isDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                      'Teams',
                      '${ctrl.totalTeams}',
                      FontAwesomeIcons.peopleGroup,
                      const Color(0xFFD97706),
                      isDark),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Members List
          Expanded(
            child: Obx(() {
              if (!ctrl.hasLoaded.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final searchResults = _searchController.text.isEmpty
                  ? ctrl.hierarchyNodes
                  : ctrl.searchNodes(_searchController.text);

              if (searchResults.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.search,
                        size: 64,
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No members found',
                        style: TextStyle(
                          fontSize: 18,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final member = searchResults[index];
                  return _buildMemberCard(member, ctrl, auth, isDark);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color, bool isDark) {
    return isDark
        ? GlassCard(
            padding: const EdgeInsets.all(16),
            opacity: 0.08,
            child: Column(
              children: [
                FaIcon(icon, color: color, size: 24),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
              ],
            ),
          )
        : Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                FaIcon(icon, color: color, size: 24),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
  }

  Widget _buildMemberCard(HierarchyNode member, HierarchyController ctrl,
      AuthController auth, bool isDark) {
    final roleColor = _getRoleColor(member.role);

    return isDark
        ? GlassCard(
            padding: const EdgeInsets.all(16),
            opacity: 0.08,
            child:
                _buildMemberCardContent(member, ctrl, auth, roleColor, isDark),
          )
        : Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: roleColor.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child:
                _buildMemberCardContent(member, ctrl, auth, roleColor, isDark),
          );
  }

  Widget _buildMemberCardContent(HierarchyNode member, HierarchyController ctrl,
      AuthController auth, Color roleColor, bool isDark) {
    return Row(
      children: [
        // Avatar
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
              _getRoleIcon(member.role),
              color: roleColor,
              size: 20,
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Member Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    member.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      member.role.displayName,
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
              Text(
                member.email,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        // Status and Actions
        Column(
          children: [
            // Status Indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: member.isActive ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),

            // Actions
            PopupMenuButton<String>(
              icon: FaIcon(
                FontAwesomeIcons.ellipsisVertical,
                size: 16,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.edit,
                          size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_status',
                  child: Row(
                    children: [
                      FaIcon(
                        member.isActive
                            ? FontAwesomeIcons.userSlash
                            : FontAwesomeIcons.userCheck,
                        size: 16,
                        color: member.isActive ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(member.isActive ? 'Deactivate' : 'Activate'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.trash,
                          size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) => _handleMenuAction(value, member, ctrl),
            ),
          ],
        ),
      ],
    );
  }

  Color _getRoleColor(HierarchyRole role) {
    switch (role) {
      case HierarchyRole.leader:
        return const Color(0xFFD97706);
      case HierarchyRole.coreTeamLeader:
        return const Color(0xFF9C27B0);
      case HierarchyRole.captain:
        return const Color(0xFF059669);
      case HierarchyRole.supervisor:
        return const Color(0xFF4CAF50);
      case HierarchyRole.monitor:
        return const Color(0xFFFF9800);
      case HierarchyRole.member:
        return const Color(0xFF047857);
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

  void _handleMenuAction(
      String action, HierarchyNode member, HierarchyController ctrl) {
    switch (action) {
      case 'edit':
        _showEditMemberDialog(context, member, ctrl);
        break;
      case 'toggle_status':
        ctrl.updateNodeStatus(member.id, !member.isActive);
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, member, ctrl);
        break;
    }
  }

  void _showAddMemberDialog(BuildContext context) {
    // TODO: Implement add member dialog
    Get.snackbar('Info', 'Add member dialog will be implemented');
  }

  void _showEditMemberDialog(
      BuildContext context, HierarchyNode member, HierarchyController ctrl) {
    // TODO: Implement edit member dialog
    Get.snackbar('Info', 'Edit member dialog will be implemented');
  }

  void _showDeleteConfirmDialog(
      BuildContext context, HierarchyNode member, HierarchyController ctrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
            'Are you sure you want to remove ${member.name} from the hierarchy?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ctrl.removeMember(member.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
