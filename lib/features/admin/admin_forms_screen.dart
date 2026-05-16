import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/controllers/theme_controller.dart';
import '../../core/widgets/glass_card.dart';
import 'member_registration_form.dart';
import 'seat_assignment_form.dart';
import 'role_management_form.dart';
import '../hierarchy/hierarchy_tree_screen.dart';

class AdminFormsScreen extends StatelessWidget {
  const AdminFormsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Forms'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Administrative Tools',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage members, assign seats, and control roles',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),

            // Forms Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _FormCard(
                  title: 'Member Registration',
                  description: 'Add new members to the committee',
                  icon: FontAwesomeIcons.userPlus,
                  color: const Color(0xFF059669),
                  onTap: () => Get.to(() => const MemberRegistrationForm()),
                  isDark: isDark,
                ),
                _FormCard(
                  title: 'Seat Assignment',
                  description: 'Assign transport seats to members',
                  icon: FontAwesomeIcons.chair,
                  color: const Color(0xFF4CAF50),
                  onTap: () => Get.to(() => const SeatAssignmentForm()),
                  isDark: isDark,
                ),
                _FormCard(
                  title: 'Role Management',
                  description: 'Manage user roles and permissions',
                  icon: FontAwesomeIcons.userShield,
                  color: const Color(0xFFD97706),
                  onTap: () => Get.to(() => const RoleManagementForm()),
                  isDark: isDark,
                ),
                _FormCard(
                  title: 'Team Hierarchy',
                  description: 'View and manage team structure',
                  icon: FontAwesomeIcons.sitemap,
                  color: const Color(0xFF9C27B0),
                  onTap: () => Get.to(() => const HierarchyTreeScreen()),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Quick Stats
            _buildQuickStats(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(bool isDark) {
    return isDark
        ? GlassCard(
            padding: const EdgeInsets.all(20),
            opacity: 0.08,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Total Members',
                        value: '300+',
                        icon: FontAwesomeIcons.users,
                        color: const Color(0xFF059669),
                        isDark: isDark,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Active Roles',
                        value: '6',
                        icon: FontAwesomeIcons.userShield,
                        color: const Color(0xFFD97706),
                        isDark: isDark,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Teams',
                        value: '15+',
                        icon: FontAwesomeIcons.peopleGroup,
                        color: const Color(0xFF4CAF50),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        : Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Total Members',
                        value: '300+',
                        icon: FontAwesomeIcons.users,
                        color: const Color(0xFF059669),
                        isDark: isDark,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Active Roles',
                        value: '6',
                        icon: FontAwesomeIcons.userShield,
                        color: const Color(0xFFD97706),
                        isDark: isDark,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Teams',
                        value: '15+',
                        icon: FontAwesomeIcons.peopleGroup,
                        color: const Color(0xFF4CAF50),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
  }

  Widget _StatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Column(
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
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _FormCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: isDark
          ? GlassCard(
              padding: const EdgeInsets.all(20),
              opacity: 0.08,
              child: _buildCardContent(),
            )
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildCardContent(),
            ),
    );
  }

  Widget _buildCardContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: FaIcon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
