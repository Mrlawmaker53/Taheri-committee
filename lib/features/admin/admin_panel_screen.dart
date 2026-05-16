import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/seed_data.dart';
import 'admin_controller.dart';
import 'user_manage_screen.dart';
import 'role_assign_screen.dart';
import 'manage_teams_screen.dart';
import '../transfers/team_manager_screen.dart';
import '../contributions/supervisor_list_screen.dart';
import '../contributions/leader_chart_screen.dart';
import 'pickup_manage_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AdminController());
    final auth = Get.find<AuthController>();

    // Role guard at widget level
    if (!auth.isSupervisorOrLeader) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: AppTokens.textMuted),
              const SizedBox(height: 16),
              Text('Access Denied',
                  style: Theme.of(context).textTheme.headlineSmall),
              Text('Supervisor or Leader role required.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTokens.textMuted)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          final isTwoCol = constraints.maxWidth > 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: FontAwesomeIcons.shieldHalved,
                  title: 'Admin Panel',
                  subtitle: auth.isLeader
                      ? 'Full access — Leader'
                      : 'Supervisor access',
                ),
                const SizedBox(height: 20),
                _buildGrid(context, isTwoCol, auth),
                if (kDebugMode && auth.isLeader) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('Developer Tools',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const FaIcon(FontAwesomeIcons.database,
                          color: Colors.green),
                      title: const Text('Seed Demo Data'),
                      subtitle: const Text(
                          'Populate Firestore with 1 team, 3 users, 2 events, 1 announcement (debug only)'),
                      trailing:
                          const FaIcon(FontAwesomeIcons.chevronRight, size: 12),
                      onTap: () async {
                        Get.dialog(
                          const Center(child: CircularProgressIndicator()),
                          barrierDismissible: false,
                        );
                        try {
                          final summary = await SeedData.seedDemoData();
                          if (Get.isDialogOpen ?? false) Get.back();
                          Get.snackbar('Seed Complete', summary,
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green.shade100,
                              colorText: Colors.green.shade900);
                        } catch (e) {
                          if (Get.isDialogOpen ?? false) Get.back();
                          Get.snackbar('Seed Failed', e.toString(),
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red.shade100,
                              colorText: Colors.red.shade900);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(BuildContext context, bool isTwoCol, AuthController auth) {
    final tiles = <_AdminTile>[
      _AdminTile(
        icon: FontAwesomeIcons.userGear,
        title: 'Manage Members',
        subtitle: 'View, activate/deactivate accounts',
        color: AppTokens.primary,
        onTap: () => Get.to(() => const UserManageScreen()),
      ),
      _AdminTile(
        icon: FontAwesomeIcons.wallet,
        title: 'Contributions Queue',
        subtitle: 'Review member contribution requests',
        color: AppTokens.warning,
        onTap: () => Get.to(() => const SupervisorListScreen()),
      ),
      if (auth.isLeader) ...[
        _AdminTile(
          icon: FontAwesomeIcons.peopleGroup,
          title: 'Manage Teams',
          subtitle: 'Create, rename, assign supervisor/leader',
          color: AppTokens.primary,
          onTap: () => Get.to(() => const ManageTeamsScreen()),
        ),
        _AdminTile(
          icon: FontAwesomeIcons.chartPie,
          title: 'Contribution Overview',
          subtitle: 'Approve group requests + charts',
          color: AppTokens.info,
          onTap: () => Get.to(() => const LeaderChartScreen()),
        ),
        _AdminTile(
          icon: FontAwesomeIcons.peopleArrows,
          title: 'Team Transfers',
          subtitle: 'Move members, approve transfers',
          color: AppTokens.success,
          onTap: () => Get.to(() => const TeamManagerScreen()),
        ),
        _AdminTile(
          icon: FontAwesomeIcons.userShield,
          title: 'Assign Roles',
          subtitle: 'Change member, supervisor, leader roles',
          color: AppTokens.danger,
          onTap: () => Get.to(() => const RoleAssignScreen()),
        ),
        _AdminTile(
          icon: FontAwesomeIcons.mapLocationDot,
          title: 'Manage Pickups',
          subtitle: 'Add, edit, delete pickup locations',
          color: AppTokens.info,
          onTap: () => Get.to(() => const PickupManageScreen()),
        ),
      ],
    ];

    if (isTwoCol) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
        ),
        itemCount: tiles.length,
        itemBuilder: (ctx, i) => tiles[i].buildCard(context),
      );
    }

    return Column(
      children: tiles.map((t) => t.buildCard(context)).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        FaIcon(icon, color: AppTokens.accent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: isDark ? Colors.white : AppTokens.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              Text(subtitle,
                  style: const TextStyle(color: AppTokens.textMuted, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminTile {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  Widget buildCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        side: const BorderSide(color: AppTokens.borderLight, width: 0.5),
      ),
      color: isDark ? AppTokens.darkCard : AppTokens.surfaceWhite,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: FaIcon(icon, color: color, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: TextStyle(
                      color: isDark ? Colors.white : AppTokens.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: AppTokens.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
