import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';
import '../theme/app_tokens.dart';

class ProfileSheet extends StatelessWidget {
  const ProfileSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final themeCtrl = Get.find<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final user = auth.currentUser.value;
      final initials = user?.initials ?? '?';
      final avatarUrl = user?.avatarUrl ?? '';
      final name = user?.fullName ?? '';
      final email = user?.email ?? '';
      final role = user?.role ?? 'member';
      final roleLabel = (role == 'admin' || role == 'leader')
          ? 'Leader'
          : role == 'supervisor'
              ? 'Supervisor'
              : 'Member';
      final roleColor = (role == 'admin' || role == 'leader')
          ? AppTokens.roleLeader
          : role == 'supervisor'
              ? AppTokens.roleSupervisor
              : AppTokens.roleMember;

      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppTokens.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppTokens.darkBorder : AppTokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTokens.primary.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 36,
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
                            fontSize: 26,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppTokens.darkTextPrimary
                        : AppTokens.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(
                    color: isDark
                        ? AppTokens.darkTextSecondary
                        : AppTokens.textSecondary,
                    fontSize: 13),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  border: Border.all(color: roleColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  roleLabel,
                  style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: isDark ? AppTokens.darkBorder : AppTokens.border),
              ListTile(
                dense: true,
                leading: FaIcon(FontAwesomeIcons.gear,
                    size: 16,
                    color: isDark
                        ? AppTokens.darkTextSecondary
                        : AppTokens.textSecondary),
                title: Text('Settings',
                    style: TextStyle(
                        color: isDark
                            ? AppTokens.darkTextPrimary
                            : AppTokens.textPrimary)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                dense: true,
                leading: FaIcon(
                    isDark ? FontAwesomeIcons.sun : FontAwesomeIcons.moon,
                    size: 16,
                    color: isDark
                        ? AppTokens.darkTextSecondary
                        : AppTokens.textSecondary),
                title: Text('Dark Mode',
                    style: TextStyle(
                        color: isDark
                            ? AppTokens.darkTextPrimary
                            : AppTokens.textPrimary)),
                trailing: Obx(() => Switch(
                      value: themeCtrl.isDark,
                      onChanged: (_) => themeCtrl.toggleTheme(),
                    )),
                onTap: () => themeCtrl.toggleTheme(),
              ),
              Divider(color: isDark ? AppTokens.darkBorder : AppTokens.border),
              ListTile(
                dense: true,
                leading: const FaIcon(
                  FontAwesomeIcons.rightFromBracket,
                  size: 16,
                  color: AppTokens.danger,
                ),
                title: const Text('Logout',
                    style: TextStyle(color: AppTokens.danger)),
                onTap: () async {
                  Navigator.pop(context);
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
                              style: TextStyle(color: AppTokens.danger)),
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
        ),
      );
    });
  }
}
