import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/auth_controller.dart';
import '../theme/app_tokens.dart';

class DrawerNavItem {
  final IconData icon;
  final String label;
  const DrawerNavItem({required this.icon, required this.label});
}

class AppDrawer extends StatelessWidget {
  final List<DrawerNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool isPermanent;

  const AppDrawer({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.isPermanent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget drawerContent = Container(
      color: isDark ? AppTokens.darkSurface : Colors.white,
      child: Column(
        children: [
          const _DrawerHeader(),
          Divider(
              height: 1,
              color: isDark ? AppTokens.darkBorder : AppTokens.border),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                final isActive = i == selectedIndex;
                return _DrawerNavTile(
                  icon: item.icon,
                  label: item.label,
                  isActive: isActive,
                  onTap: () => onSelect(i),
                );
              },
            ),
          ),
          Divider(
              height: 1,
              color: isDark ? AppTokens.darkBorder : AppTokens.border),
          _DrawerFooter(),
        ],
      ),
    );

    if (isPermanent) {
      return drawerContent;
    }

    return Drawer(child: SafeArea(child: drawerContent));
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      final user = auth.currentUser.value;
      final initials = user?.initials ?? '?';
      final avatarUrl = user?.avatarUrl ?? '';
      final name = user?.fullName ?? 'Loading...';
      final role = user?.role ?? '';
      final roleLabel = role == 'admin' || role == 'leader'
          ? 'Leader'
          : role == 'supervisor'
              ? 'Supervisor'
              : 'Member';

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final roleColor = role == 'admin' || role == 'leader'
          ? AppTokens.roleLeader
          : role == 'supervisor'
              ? AppTokens.roleSupervisor
              : AppTokens.roleMember;

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 18),
        decoration: BoxDecoration(
          color: isDark ? AppTokens.darkCard : AppTokens.primarySubtle,
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTokens.primary.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: AppTokens.primary,
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                onBackgroundImageError:
                    avatarUrl.isNotEmpty ? (_, __) {} : null,
                child: avatarUrl.isEmpty
                    ? Text(
                        initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                        color: isDark
                            ? AppTokens.darkTextPrimary
                            : AppTokens.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: roleColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                          color: roleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _DrawerNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDestructive;
  final VoidCallback onTap;

  const _DrawerNavTile({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppTokens.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? const Border(left: BorderSide(color: AppTokens.primary, width: 3))
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: FaIcon(
          icon,
          size: 16,
          color: isDestructive
              ? AppTokens.danger
              : isActive
                  ? AppTokens.primaryDark
                  : (isDark
                      ? AppTokens.darkTextSecondary
                      : AppTokens.textSecondary),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isDestructive
                ? AppTokens.danger
                : isActive
                    ? AppTokens.primaryDark
                    : (isDark
                        ? AppTokens.darkTextPrimary
                        : AppTokens.textPrimary),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTokens.darkCard : AppTokens.surfaceElevated,
      ),
      child: Column(
        children: [
          _DrawerNavTile(
            icon: FontAwesomeIcons.gear,
            label: 'Settings',
            isActive: false,
            onTap: () {},
          ),
          _DrawerNavTile(
            icon: FontAwesomeIcons.rightFromBracket,
            label: 'Logout',
            isActive: false,
            isDestructive: true,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Logout',
                          style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) await auth.signOut();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
