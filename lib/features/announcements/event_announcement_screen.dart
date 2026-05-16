import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/controllers/theme_controller.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/models/event_announcement_model.dart';
import 'event_announcement_controller.dart';
import 'create_event_announcement_screen.dart';

class EventAnnouncementScreen extends StatelessWidget {
  const EventAnnouncementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(EventAnnouncementController());
    final auth = Get.find<AuthController>();
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Announcements'),
        actions: [
          if (auth.isSupervisorOrLeader)
            IconButton(
              onPressed: () =>
                  Get.to(() => const CreateEventAnnouncementScreen()),
              icon: const FaIcon(FontAwesomeIcons.plus),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: Obx(() {
          if (!ctrl.hasLoaded.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (ctrl.announcements.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ctrl.announcements.length,
            itemBuilder: (context, index) {
              final announcement = ctrl.announcements[index];
              return _AnnouncementCard(
                announcement: announcement,
                isDark: isDark,
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.bullhorn,
            size: 64,
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No Event Announcements',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Event announcements will appear here',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final EventAnnouncementModel announcement;
  final bool isDark;

  const _AnnouncementCard({
    required this.announcement,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<EventAnnouncementController>();
    final auth = Get.find<AuthController>();
    final userResponse = ctrl.getUserResponse(announcement.id);
    final hasResponded = ctrl.hasUserResponded(announcement.id);
    final isPastDeadline = announcement.deadlineAt != null &&
        DateTime.now().isAfter(announcement.deadlineAt!);

    return isDark
        ? GlassCard(
            padding: const EdgeInsets.all(16),
            opacity: 0.08,
            child: _buildCardContent(context, ctrl, auth, userResponse,
                hasResponded, isPastDeadline),
          )
        : Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
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
            child: _buildCardContent(context, ctrl, auth, userResponse,
                hasResponded, isPastDeadline),
          );
  }

  Widget _buildCardContent(
    BuildContext context,
    EventAnnouncementController ctrl,
    AuthController auth,
    AttendanceResponse? userResponse,
    bool hasResponded,
    bool isPastDeadline,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and event info
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.calendarDays,
                        size: 14,
                        color: Color(0xFF059669),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        announcement.eventTitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (auth.isSupervisorOrLeader)
              PopupMenuButton<String>(
                icon: FaIcon(
                  FontAwesomeIcons.ellipsisVertical,
                  size: 16,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'deactivate',
                    child: Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.trash,
                          size: 16,
                          color: Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text('Deactivate'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'deactivate') {
                    _showDeactivateDialog(context);
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Description
        Text(
          announcement.description,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        // Event date and deadline
        Row(
          children: [
            FaIcon(
              FontAwesomeIcons.clock,
              size: 14,
              color: isDark ? Colors.white54 : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              'Event: ${_formatDate(announcement.eventDate)}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
            if (announcement.deadlineAt != null) ...[
              const SizedBox(width: 16),
              FaIcon(
                FontAwesomeIcons.hourglassEnd,
                size: 14,
                color: isPastDeadline ? Colors.red : Colors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                'Deadline: ${_formatDate(announcement.deadlineAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isPastDeadline ? Colors.red : Colors.orange,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Attendance statistics (for supervisors)
        if (auth.isSupervisorOrLeader) ...[
          _buildAttendanceStats(),
          const SizedBox(height: 16),
        ],

        // User response section
        if (!auth.isSupervisorOrLeader) ...[
          _buildUserResponseSection(
              context, ctrl, userResponse, hasResponded, isPastDeadline),
        ],
      ],
    );
  }

  Widget _buildAttendanceStats() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF059669).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Statistics',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatChip(
                label: 'Yes',
                count: announcement.yesCount,
                color: Colors.green,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'No',
                count: announcement.noCount,
                color: Colors.red,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Pending',
                count: announcement.pendingCount,
                color: Colors.orange,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserResponseSection(
    BuildContext context,
    EventAnnouncementController ctrl,
    AttendanceResponse? userResponse,
    bool hasResponded,
    bool isPastDeadline,
  ) {
    if (hasResponded) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: userResponse?.response == 'yes'
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: userResponse?.response == 'yes'
                ? Colors.green.withOpacity(0.3)
                : Colors.red.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            FaIcon(
              userResponse?.response == 'yes'
                  ? FontAwesomeIcons.checkCircle
                  : FontAwesomeIcons.xmarkCircle,
              color:
                  userResponse?.response == 'yes' ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You responded: ${userResponse?.response.toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: userResponse?.response == 'yes'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  if (userResponse?.note != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Note: ${userResponse!.note}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isPastDeadline) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
          ),
        ),
        child: const Row(
          children: [
            FaIcon(
              FontAwesomeIcons.hourglassEnd,
              color: Colors.red,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Response deadline has passed',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Will you attend this event?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showResponseDialog(context, ctrl, 'yes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                icon: const FaIcon(FontAwesomeIcons.check, size: 14),
                label: const Text('Yes'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showResponseDialog(context, ctrl, 'no'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
                label: const Text('No'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showResponseDialog(
    BuildContext context,
    EventAnnouncementController ctrl,
    String response,
  ) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Attendance - ${response.toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to respond "${response.toUpperCase()}" to this event?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Optional note',
                hintText: 'Add any additional information...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ctrl.respondToAnnouncement(
                announcementId: announcement.id,
                response: response,
                note: noteController.text.trim().isEmpty
                    ? null
                    : noteController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: response == 'yes' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Announcement'),
        content: Text(
          'Are you sure you want to deactivate "${announcement.title}"? This will remove it from all users\' feeds.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Get.find<EventAnnouncementController>()
                  .deactivateAnnouncement(announcement.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
