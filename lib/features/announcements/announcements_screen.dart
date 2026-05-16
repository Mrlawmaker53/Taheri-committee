import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/widgets/shimmer_widgets.dart';
import 'announcements_controller.dart';
import 'create_announcement_screen.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AnnouncementsController());
    final auth = Get.find<AuthController>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {},
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
            return Obx(() {
              if (!ctrl.hasLoaded.value) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: padding / 2),
                  child: const ListShimmer(itemCount: 5),
                );
              }
              if (ctrl.announcements.isEmpty) {
                return ListView(
                  padding: EdgeInsets.all(padding),
                  children: const [
                    SizedBox(height: 80),
                    Center(
                      child: Column(
                        children: [
                          FaIcon(FontAwesomeIcons.bullhorn,
                              size: 56, color: Colors.white24),
                          SizedBox(height: 16),
                          Text('No announcements yet',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 16)),
                          SizedBox(height: 8),
                          Text('Check back later for updates.',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return ListView.builder(
                padding: EdgeInsets.all(padding),
                itemCount: ctrl.announcements.length,
                itemBuilder: (ctx, i) => _AnnouncementCard(
                  announcement: ctrl.announcements[i],
                  canDelete: auth.isSupervisorOrLeader,
                  ctrl: ctrl,
                ),
              );
            });
          },
        ),
      ),
      floatingActionButton: auth.isSupervisorOrLeader
          ? FloatingActionButton.extended(
              onPressed: () => Get.to(() => const CreateAnnouncementScreen()),
              icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
              label: const Text('New Announcement'),
            )
          : null,
    );
  }
}

class _AnnouncementCard extends StatefulWidget {
  final AnnouncementModel announcement;
  final bool canDelete;
  final AnnouncementsController ctrl;

  const _AnnouncementCard({
    required this.announcement,
    required this.canDelete,
    required this.ctrl,
  });

  @override
  State<_AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<_AnnouncementCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.announcement;
    final audienceColor = a.audience == 'all'
        ? Colors.blue
        : a.audience == 'supervisors'
            ? Colors.orange
            : Colors.green;
    final audienceLabel = a.audience == 'all'
        ? 'All Members'
        : a.audience == 'supervisors'
            ? 'Supervisors'
            : 'Leaders';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C27B0).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF9C27B0).withOpacity(0.3),
                      ),
                    ),
                    child: const FaIcon(FontAwesomeIcons.bullhorn,
                        color: Color(0xFFCE93D8), size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              a.authorName,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11),
                            ),
                            const Text(' · ',
                                style: TextStyle(color: Colors.white30)),
                            Text(
                              DateFormat('dd MMM yyyy').format(a.createdAt),
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: audienceColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(audienceLabel,
                            style: TextStyle(
                                color: audienceColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 4),
                      FaIcon(
                        _expanded
                            ? FontAwesomeIcons.chevronUp
                            : FontAwesomeIcons.chevronDown,
                        size: 12,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  a.body,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.5),
                ),
                if (widget.canDelete) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _confirmDelete(context, a),
                      icon: const FaIcon(FontAwesomeIcons.trash,
                          size: 12, color: Colors.red),
                      label: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AnnouncementModel a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Remove "${a.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.ctrl.deleteAnnouncement(a.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
