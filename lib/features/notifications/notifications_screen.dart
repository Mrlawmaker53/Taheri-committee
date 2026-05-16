import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/controllers/notification_controller.dart';
import '../../core/models/notification_model.dart';
import '../../core/widgets/shimmer_widgets.dart';
import 'notification_detail_screen.dart';
import 'notification_response_report_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NotificationController>();

    return Scaffold(
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return Obx(() {
            if (!ctrl.hasLoaded.value) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: padding / 2),
                child: const NotificationsLoadingShimmer(),
              );
            }
            if (ctrl.notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(FontAwesomeIcons.bellSlash,
                        size: 56, color: Colors.white24),
                    SizedBox(height: 16),
                    Text('No notifications',
                        style: TextStyle(color: Colors.white54, fontSize: 16)),
                    SizedBox(height: 8),
                    Text("You're all caught up!",
                        style: TextStyle(color: Colors.white38, fontSize: 13)),
                  ],
                ),
              );
            }

            return Column(
              children: [
                if (ctrl.unreadCount.value > 0)
                  Padding(
                    padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
                    child: Row(
                      children: [
                        Text(
                          '${ctrl.unreadCount.value} unread',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: ctrl.markAllAsRead,
                          icon: const FaIcon(FontAwesomeIcons.checkDouble,
                              size: 12),
                          label: const Text('Mark all read',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(padding),
                    itemCount: ctrl.notifications.length,
                    itemBuilder: (ctx, i) =>
                        _NotifCard(notif: ctrl.notifications[i], ctrl: ctrl),
                  ),
                ),
              ],
            );
          });
        },
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  final NotificationController ctrl;

  const _NotifCard({required this.notif, required this.ctrl});

  IconData _typeIcon(String type) {
    switch (type) {
      case 'contribution':
        return FontAwesomeIcons.wallet;
      case 'transfer':
        return FontAwesomeIcons.arrowRightArrowLeft;
      case 'event':
      case 'event_rsvp':
        return FontAwesomeIcons.calendarDays;
      case 'announcement':
        return FontAwesomeIcons.bullhorn;
      case 'group_request':
        return FontAwesomeIcons.layerGroup;
      default:
        return FontAwesomeIcons.bell;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notif.isRead;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isUnread
            ? const Color(0xFF059669).withOpacity(0.08)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? const Color(0xFF059669).withOpacity(0.35)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: const Color(0xFF059669).withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (isUnread) ctrl.markAsRead(notif.id);
            Get.to(() => NotificationDetailScreen(notification: notif));
          },
          onLongPress: () {
            // Sup/Leader can view response breakdown for actionable notifs.
            final auth = Get.find<AuthController>();
            if (notif.requiresResponse && auth.isSupervisorOrLeader) {
              Get.to(() => NotificationResponseReportScreen(
                    notification: notif,
                  ));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUnread
                        ? const Color(0xFF059669).withOpacity(0.15)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isUnread
                          ? const Color(0xFF059669).withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: FaIcon(
                    _typeIcon(notif.type),
                    size: 16,
                    color: isUnread ? const Color(0xFF059669) : Colors.white38,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF059669),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.body,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a')
                                .format(notif.createdAt),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 10),
                          ),
                          if (notif.requiresResponse) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFD97706).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color(0xFFD97706)
                                        .withOpacity(0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FaIcon(FontAwesomeIcons.handPointer,
                                      size: 9, color: Color(0xFFFFD54F)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Action Required',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFFD54F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Public shimmer wrapper used by callers that show shimmer while the first
/// snapshot of `notifications` is loading. The controller listens via
/// snapshots() so we expose a simple convenience widget.
class NotificationsLoadingShimmer extends StatelessWidget {
  const NotificationsLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(6, (_) => const NotificationShimmer()),
    );
  }
}
