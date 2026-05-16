import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/controllers/notification_controller.dart';
import '../../core/models/notification_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/shimmer_widgets.dart';

/// Supervisor / leader screen showing who responded (and how) to a single
/// notification. Reachable from a long-press on a sent notification, or from
/// the event detail screen (View RSVP Responses).
class NotificationResponseReportScreen extends StatefulWidget {
  final NotificationModel notification;

  const NotificationResponseReportScreen({
    super.key,
    required this.notification,
  });

  @override
  State<NotificationResponseReportScreen> createState() =>
      _NotificationResponseReportScreenState();
}

class _NotificationResponseReportScreenState
    extends State<NotificationResponseReportScreen> {
  final RxList<UserModel> _eligibleMembers = <UserModel>[].obs;
  final RxBool _membersLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _loadEligibleMembers();
  }

  /// Eligible recipients = all users in the same target scope that the
  /// notification was sent to. Used to compute Pending count.
  Future<void> _loadEligibleMembers() async {
    _membersLoading.value = true;
    try {
      final n = widget.notification;
      Query<Map<String, dynamic>> q =
          FirebaseFirestore.instance.collection('users');
      if (n.targetType == 'team' && n.eventId == null) {
        // Targeted by team — fall back to all users; the notifications doc
        // itself doesn't store targetTeamId on the per-user copy.
      }
      // If we have a richer targeting metadata, prefer the source doc.
      final src = await _resolveSourceDoc(n);
      if (src != null) {
        final tType = src['targetType']?.toString() ?? 'all';
        if (tType == 'team' && src['targetTeamId'] != null) {
          q = q.where('teamId', isEqualTo: src['targetTeamId']);
        } else if (tType == 'role' && src['targetRole'] != null) {
          q = q.where('role', isEqualTo: src['targetRole']);
        } else if (tType == 'individual' && src['targetUserId'] != null) {
          q = q.where(FieldPath.documentId,
              isEqualTo: src['targetUserId']);
        }
      }
      q = q.where('isActive', isEqualTo: true);
      final snap = await q.get();
      _eligibleMembers.value = snap.docs
          .map((d) => UserModel.fromFirestore(d))
          .toList();
    } catch (_) {
      // Fallback: empty list (Pending count will show 0).
    } finally {
      _membersLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> _resolveSourceDoc(
      NotificationModel n) async {
    try {
      if (n.eventId != null && n.eventId!.isNotEmpty) {
        final doc = await FirestoreService.events.doc(n.eventId).get();
        if (doc.exists) return doc.data() as Map<String, dynamic>;
      }
      if (n.announcementId != null && n.announcementId!.isNotEmpty) {
        final doc = await FirestoreService.announcements
            .doc(n.announcementId)
            .get();
        if (doc.exists) return doc.data() as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final ctrl = Get.find<NotificationController>();
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronLeft,
              color: Colors.white, size: 16),
          onPressed: () => Get.back(),
        ),
        title: const Text('Response Report'),
        actions: [
          if (auth.isLeader)
            IconButton(
              tooltip: 'Export CSV',
              onPressed: () => _exportCsv(),
              icon: const FaIcon(FontAwesomeIcons.fileExport,
                  size: 16, color: Colors.white),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return StreamBuilder<List<NotificationResponseModel>>(
            stream: ctrl.streamResponsesFor(n.id),
            builder: (ctx, snap) {
              final responses = snap.data ?? const [];
              final loading =
                  snap.connectionState == ConnectionState.waiting;
              return SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NotificationSummary(notification: n),
                    const SizedBox(height: 16),
                    Obx(() {
                      final eligible = _eligibleMembers.length;
                      final responded = responses.length;
                      final pending =
                          (eligible - responded).clamp(0, 1 << 31);
                      return _StatsRow(
                        total: eligible == 0 ? responded : eligible,
                        responded: responded,
                        pending: pending,
                        membersLoading: _membersLoading.value,
                      );
                    }),
                    const SizedBox(height: 20),
                    if (loading)
                      const ListShimmer(itemCount: 4)
                    else ...[
                      _ResponseBreakdown(
                        responses: responses,
                        options: n.responseOptions.isEmpty
                            ? const ['Yes', 'No', 'Maybe']
                            : n.responseOptions,
                      ),
                      const SizedBox(height: 20),
                      _RespondedList(responses: responses),
                      const SizedBox(height: 20),
                      Obx(() {
                        if (_membersLoading.value) {
                          return const ListShimmer(itemCount: 3);
                        }
                        final respondedIds =
                            responses.map((r) => r.userId).toSet();
                        final pending = _eligibleMembers
                            .where((u) => !respondedIds.contains(u.uid))
                            .toList();
                        return _PendingList(members: pending);
                      }),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _exportCsv() async {
    final ctrl = Get.find<NotificationController>();
    // Snapshot the current responses synchronously by taking the latest
    // value from the stream's first emit.
    final responses = await ctrl
        .streamResponsesFor(widget.notification.id)
        .first;
    final buf = StringBuffer();
    buf.writeln('Name,Team,Response,Time');
    for (final r in responses) {
      buf.writeln([
        _csv(r.userName),
        _csv(r.teamId),
        _csv(r.response),
        _csv(DateFormat('yyyy-MM-dd HH:mm:ss').format(r.respondedAt)),
      ].join(','));
    }
    final csv = buf.toString();
    if (kIsWeb) {
      // For web, copy to clipboard (browser download requires dart:html
      // which the project doesn't currently include).
      await Clipboard.setData(ClipboardData(text: csv));
      Get.snackbar(
        'CSV Copied',
        'Report copied to clipboard. Paste into a spreadsheet.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );
    } else {
      await Clipboard.setData(ClipboardData(text: csv));
      Get.snackbar(
        'CSV Ready',
        'Report copied to clipboard.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    debugPrint('=== CSV EXPORT ===\n$csv');
  }

  String _csv(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }
}

// ─── Notification summary card ───────────────────────────────────────────────
class _NotificationSummary extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationSummary({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.bell,
                    size: 14, color: Color(0xFF047857)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notification.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notification.body,
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade700),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              'Sent ${DateFormat('dd MMM yyyy, hh:mm a').format(notification.createdAt)}',
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats row ───────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int total;
  final int responded;
  final int pending;
  final bool membersLoading;

  const _StatsRow({
    required this.total,
    required this.responded,
    required this.pending,
    required this.membersLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Total Sent',
            value: '$total',
            icon: FontAwesomeIcons.paperPlane,
            color: const Color(0xFF047857),
            loading: membersLoading,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: 'Responded',
            value: '$responded',
            icon: FontAwesomeIcons.userCheck,
            color: Colors.green,
            loading: false,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: 'Pending',
            value: '$pending',
            icon: FontAwesomeIcons.userClock,
            color: Colors.orange,
            loading: membersLoading,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool loading;
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FaIcon(icon, size: 14, color: color),
            const SizedBox(height: 6),
            loading
                ? const ShimmerBox(width: 32, height: 22)
                : Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

// ─── Response breakdown bars ─────────────────────────────────────────────────
class _ResponseBreakdown extends StatelessWidget {
  final List<NotificationResponseModel> responses;
  final List<String> options;

  const _ResponseBreakdown({
    required this.responses,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final total = responses.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Response Breakdown',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            ...options.map((opt) {
              final count = responses
                  .where((r) =>
                      r.response.toLowerCase() == opt.toLowerCase())
                  .length;
              final pct = total == 0 ? 0.0 : count / total;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _BreakdownRow(
                  label: opt,
                  count: count,
                  pct: pct,
                  color: _colorFor(opt),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _colorFor(String l) {
    final s = l.toLowerCase();
    if (s == 'yes' || s == 'confirm' || s == 'attending') {
      return Colors.green;
    }
    if (s == 'no' || s == 'decline' || s == 'cannot') return Colors.red;
    if (s == 'maybe') return Colors.amber.shade700;
    return const Color(0xFF047857);
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final int count;
  final double pct;
  final Color color;
  const _BreakdownRow({
    required this.label,
    required this.count,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Text(
              '$count  •  ${(pct * 100).toStringAsFixed(0)}%',
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(builder: (ctx, c) {
          final maxW = c.maxWidth;
          return Stack(
            children: [
              Container(
                height: 8,
                width: maxW,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                height: 8,
                width: maxW * pct,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

// ─── Responded list ──────────────────────────────────────────────────────────
class _RespondedList extends StatelessWidget {
  final List<NotificationResponseModel> responses;
  const _RespondedList({required this.responses});

  @override
  Widget build(BuildContext context) {
    if (responses.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Responded',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        const SizedBox(height: 8),
        ...responses.map((r) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF059669),
                  child: Text(
                    _initials(r.userName),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  r.userName.isEmpty ? r.userId : r.userName,
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  DateFormat('dd MMM, hh:mm a').format(r.respondedAt),
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade600),
                ),
                trailing: _ResponseChip(label: r.response),
              ),
            )),
      ],
    );
  }

  String _initials(String n) {
    final parts = n.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}

class _ResponseChip extends StatelessWidget {
  final String label;
  const _ResponseChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _colorFor(String l) {
    final s = l.toLowerCase();
    if (s == 'yes' || s == 'confirm' || s == 'attending') {
      return Colors.green.shade700;
    }
    if (s == 'no' || s == 'decline' || s == 'cannot') {
      return Colors.red.shade700;
    }
    if (s == 'maybe') return Colors.amber.shade800;
    return const Color(0xFF047857);
  }
}

// ─── Pending (no response yet) ───────────────────────────────────────────────
class _PendingList extends StatelessWidget {
  final List<UserModel> members;
  const _PendingList({required this.members});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Pending (${members.length})',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 8),
        ...members.map((u) => Card(
              color: Colors.grey.shade50,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade400,
                  child: Text(
                    u.initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  u.fullName,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                trailing: Text(
                  'No response',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic),
                ),
              ),
            )),
      ],
    );
  }
}

// Suppress unused-import warning (json encoder kept for future export needs).
// ignore: unused_element
const _kJsonEncoder = JsonEncoder.withIndent('  ');
