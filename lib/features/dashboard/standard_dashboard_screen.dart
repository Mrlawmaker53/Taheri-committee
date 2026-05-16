import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/controllers/theme_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/notification_permission_widget.dart';
import '../admin/admin_forms_screen.dart';
import '../announcements/event_announcement_screen.dart';
import '../hierarchy/hierarchy_tree_screen.dart';
import '../transport/transport_screen.dart';
import 'dashboard_controller.dart';

class StandardDashboardScreen extends StatefulWidget {
  const StandardDashboardScreen({super.key});

  @override
  State<StandardDashboardScreen> createState() =>
      _StandardDashboardScreenState();
}

class _StandardDashboardScreenState extends State<StandardDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(DashboardController());
    final auth = Get.find<AuthController>();
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return Scaffold(
      key: _scaffoldKey,
      body: Obx(() {
        if (!auth.isProfileLoaded.value || ctrl.isLoading.value) {
          return _buildLoadingState(isDark);
        }

        return _buildBody(_selectedIndex, ctrl, auth, isDark);
      }),
    );
  }

  Widget _buildBody(int selectedIndex, DashboardController ctrl,
      AuthController auth, bool isDark) {
    switch (selectedIndex) {
      case 0:
        return _buildDashboardContent(ctrl, auth, isDark);
      case 1:
        return const EventAnnouncementScreen();
      case 2:
        return const TransportScreen();
      case 3:
        return const HierarchyTreeScreen();
      case 4:
        return const AdminFormsScreen();
      default:
        return _buildDashboardContent(ctrl, auth, isDark);
    }
  }

  Widget _buildDashboardContent(
      DashboardController ctrl, AuthController auth, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          _buildWelcomeSection(auth, isDark),
          const SizedBox(height: 20),

          // Stats Cards (for supervisors/leaders)
          if (auth.isSupervisorOrLeader) ...[
            _buildStatsGrid(ctrl, isDark),
            const SizedBox(height: 20),
          ],

          // Member-only section: show their own team info
          if (auth.isMember) ...[
            _buildMemberInfoCard(auth, isDark),
            const SizedBox(height: 20),

            // Notification permission widget for web users
            const NotificationPermissionWidget(),
            const SizedBox(height: 20),
          ],

          // Recent Activity
          _buildRecentActivity(isDark),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(AuthController auth, bool isDark) {
    final firstName =
        auth.currentUser.value?.fullName.split(' ').first ?? 'User';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTokens.heroGradient,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        boxShadow: AppTokens.shadowLg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  firstName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Here\'s what\'s happening today',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.mosque,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberInfoCard(AuthController auth, bool isDark) {
    final teamId = auth.currentUser.value?.teamId ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTokens.darkCard : AppTokens.primaryLight,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTokens.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.group, color: AppTokens.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Team',
                    style: TextStyle(
                        color:
                            isDark ? Colors.white70 : AppTokens.textSecondary,
                        fontSize: 12)),
                Text(teamId.isEmpty ? 'Not assigned' : 'Team: $teamId',
                    style: TextStyle(
                        color: isDark ? Colors.white : AppTokens.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('Role: ${auth.currentUser.value?.role ?? 'member'}',
                    style: const TextStyle(color: AppTokens.textMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(DashboardController ctrl, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 6, // Changed from 2 to 6 for 6 cards in a row
      crossAxisSpacing: 6, // Reduced spacing for more cards
      mainAxisSpacing: 6, // Reduced spacing for more cards
      childAspectRatio: 1.8, // Adjusted aspect ratio for horizontal layout
      children: [
        _buildStatCard(
          'Members',
          '${ctrl.memberCount}',
          FontAwesomeIcons.users,
          AppTokens.accent,
          isDark,
        ),
        _buildStatCard(
          'Teams',
          '${ctrl.teamCount}',
          FontAwesomeIcons.peopleGroup,
          AppTokens.success,
          isDark,
        ),
        _buildStatCard(
          'Pending',
          '${ctrl.pendingGroupRequests}',
          FontAwesomeIcons.clock,
          AppTokens.warning,
          isDark,
        ),
        _buildStatCard(
          'Events',
          '${ctrl.eventCount}',
          FontAwesomeIcons.calendar,
          AppTokens.info,
          isDark,
        ),
        _buildStatCard(
          'Active',
          '${ctrl.memberCount}',
          FontAwesomeIcons.userCheck,
          const Color(0xFF4CAF50),
          isDark,
        ),
        _buildStatCard(
          'Transfers',
          '${ctrl.pendingTransfers}',
          FontAwesomeIcons.exchange,
          const Color(0xFF9C27B0),
          isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(10), // Reduced further for horizontal layout
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.08),
            color.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6, // Reduced shadow for horizontal layout
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 6), // More compact padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with creative background - smaller for horizontal layout
            Container(
              padding: const EdgeInsets.all(6), // Reduced padding
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8), // Smaller border radius
              ),
              child: FaIcon(icon,
                  color: color, size: 16), // Further reduced icon size
            ),
            const SizedBox(height: 4), // Reduced spacing
            // Value with enhanced styling - more compact
            Text(
              value,
              style: TextStyle(
                fontSize: 14, // Reduced further for horizontal layout
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 1), // Minimal spacing
            // Title with better styling - more compact
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppTokens.textMuted,
                fontSize: 8, // Reduced further for horizontal layout
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 16, // Reduced from 20 to 16
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8), // Reduced from 16 to 8
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), // Reduced from 12 to 10
            gradient: isDark
                ? LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.02),
                      Colors.white.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Colors.grey.shade50.withOpacity(0.5),
                      Colors.grey.shade100.withOpacity(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: Border.all(
              color:
                  isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 6, // Reduced from 8 to 6
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10), // Reduced from 16 to 10
            child: Column(
              children: [
                _buildActivityItem(
                  'New announcement posted',
                  'Admin Team',
                  FontAwesomeIcons.bullhorn,
                  AppTokens.accentPurple,
                  '2 hours ago',
                  isDark,
                ),
                Divider(
                    color:
                        isDark ? AppTokens.darkBorder : AppTokens.borderLight),
                _buildActivityItem(
                  'Transport schedule updated',
                  'Transport Manager',
                  FontAwesomeIcons.bus,
                  AppTokens.primary,
                  '5 hours ago',
                  isDark,
                ),
                Divider(
                    color:
                        isDark ? AppTokens.darkBorder : AppTokens.borderLight),
                _buildActivityItem(
                  'New member added',
                  'Team Leader',
                  FontAwesomeIcons.userPlus,
                  AppTokens.accentGold,
                  '1 day ago',
                  isDark,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon,
      Color color, String time, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: FaIcon(icon, color: color, size: 16),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey.shade500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppTokens.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Dashboard...',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBottomSheet() {
    final auth = Get.find<AuthController>();
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTokens.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Profile Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppTokens.heroGradient,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      auth.currentUser.value?.fullName
                              .substring(0, 1)
                              .toUpperCase() ??
                          'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.currentUser.value?.fullName ?? 'Unknown User',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auth.currentUser.value?.email ?? '',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTokens.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                              color: AppTokens.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          auth.currentUser.value?.role.toUpperCase() ??
                              'MEMBER',
                          style: const TextStyle(
                            color: AppTokens.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          ListTile(
            leading: FaIcon(
              FontAwesomeIcons.userEdit,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
            title: Text(
              'Edit Profile',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showProfileSettings();
            },
          ),
          ListTile(
            leading: FaIcon(
              FontAwesomeIcons.cog,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
            title: Text(
              'Settings',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showProfileSettings();
            },
          ),
          ListTile(
            leading: const FaIcon(
              FontAwesomeIcons.signOutAlt,
              color: Colors.red,
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showProfileSettings() {
    // TODO: Implement profile settings screen
    Get.snackbar('Profile Settings', 'Profile settings will be implemented');
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final auth = Get.find<AuthController>();
              auth.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
