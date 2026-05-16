import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/auth_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/theme_controller.dart';
import '../theme/app_tokens.dart';
import '../routes/app_routes.dart';
import 'profile_sheet.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showHamburger;
  final VoidCallback? onHamburgerTap;

  const TopBar({
    super.key,
    required this.showHamburger,
    this.onHamburgerTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: isDark ? AppTokens.darkSurface : Colors.white,
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      leading: showHamburger
          ? IconButton(
              icon: FaIcon(FontAwesomeIcons.bars,
                  color: isDark
                      ? AppTokens.darkTextPrimary
                      : AppTokens.textPrimary,
                  size: 18),
              onPressed: onHamburgerTap,
            )
          : null,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(FontAwesomeIcons.mosque, color: AppTokens.primary, size: 16),
          const SizedBox(width: 8),
          Text(
            'Taheri Committee',
            style: TextStyle(
              color: isDark ? AppTokens.darkTextPrimary : AppTokens.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark ? AppTokens.darkBorder : AppTokens.border,
        ),
      ),
      actions: [
        _ThemeToggle(),
        _NotificationBell(),
        const SizedBox(width: 4),
        _AvatarChip(auth: auth),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ThemeController>();
    return Obx(() {
      final isDark = ctrl.isDark;
      return IconButton(
        tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
        icon: Icon(
          isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
          color: isDark ? AppTokens.accentGold : AppTokens.textSecondary,
          size: 20,
        ),
        onPressed: ctrl.toggleTheme,
      );
    });
  }
}

class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetX<NotificationController>(
      builder: (ctrl) {
        final count = ctrl.unreadCount.value;
        final hasUnread = count > 0;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip:
                  hasUnread ? '$count unread notification(s)' : 'Notifications',
              icon: FaIcon(
                hasUnread ? FontAwesomeIcons.solidBell : FontAwesomeIcons.bell,
                color: hasUnread
                    ? AppTokens.accentGold
                    : (Theme.of(context).brightness == Brightness.dark
                        ? AppTokens.darkTextSecondary
                        : AppTokens.textSecondary),
                size: 18,
              ),
              onPressed: () => Get.toNamed(AppRoutes.notifications),
            ),
            if (hasUnread)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTokens.accentRose,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          height: 1.0,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AvatarChip extends StatelessWidget {
  final AuthController auth;
  const _AvatarChip({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = auth.currentUser.value;
      final initials = user?.initials ?? '?';
      final avatarUrl = user?.avatarUrl ?? '';
      return GestureDetector(
        onTap: () => _showProfileSheet(context),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppTokens.primary,
          backgroundImage:
              avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          onBackgroundImageError: avatarUrl.isNotEmpty ? (_, __) {} : null,
          child: avatarUrl.isEmpty
              ? Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                )
              : null,
        ),
      );
    });
  }

  void _showProfileSheet(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    if (isWide) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          alignment: Alignment.topRight,
          insetPadding:
              const EdgeInsets.only(top: kToolbarHeight + 8, right: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const SizedBox(width: 300, child: ProfileSheet()),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => const ProfileSheet(),
      );
    }
  }
}
