import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/controllers/notification_controller.dart';
import '../../core/models/notification_model.dart';
import '../../core/widgets/shimmer_widgets.dart';

class NotificationDetailScreen extends StatefulWidget {
  final NotificationModel notification;
  const NotificationDetailScreen({super.key, required this.notification});

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  String? _selectedResponse;
  NotificationResponseModel? _existingResponse;
  bool _checkingExisting = true;

  @override
  void initState() {
    super.initState();
    _loadExistingResponse();
    // Mark notification as read on open (best-effort).
    final ctrl = Get.find<NotificationController>();
    if (!widget.notification.isRead) {
      ctrl.markAsRead(widget.notification.id);
    }
  }

  Future<void> _loadExistingResponse() async {
    final ctrl = Get.find<NotificationController>();
    final existing = await ctrl.existingResponseFor(widget.notification.id);
    if (!mounted) return;
    setState(() {
      _existingResponse = existing;
      _checkingExisting = false;
    });
  }

  String _responseTypeFor(NotificationModel n) {
    if (n.notifType == 'event_rsvp') return 'event_rsvp';
    return 'announcement_response';
  }

  Future<void> _submit() async {
    final r = _selectedResponse;
    if (r == null) return;
    final ctrl = Get.find<NotificationController>();
    final ok = await ctrl.submitResponse(
      notificationId: widget.notification.id,
      response: r,
      type: _responseTypeFor(widget.notification),
      eventId: widget.notification.eventId,
      announcementId: widget.notification.announcementId,
    );
    if (ok && mounted) {
      await _loadExistingResponse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final hasResponded = _existingResponse != null;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronLeft,
              color: Colors.white, size: 16),
          onPressed: () => Get.back(),
        ),
        title: Text(_titleForType(n.notifType),
            style: const TextStyle(fontSize: 16)),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NotificationCard(notification: n),
                const SizedBox(height: 20),
                if (n.requiresResponse) ...[
                  if (_checkingExisting)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: ListShimmer(itemCount: 1),
                    )
                  else if (hasResponded)
                    _RespondedView(response: _existingResponse!)
                  else
                    _ResponseForm(
                      options: n.responseOptions.isEmpty
                          ? const ['Yes', 'No']
                          : n.responseOptions,
                      selected: _selectedResponse,
                      onSelect: (v) => setState(() => _selectedResponse = v),
                      onSubmit: _submit,
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _titleForType(String type) {
    switch (type) {
      case 'event_rsvp':
        return 'Event Notification';
      case 'announcement':
        return 'Announcement';
      case 'contribution':
        return 'Contribution Update';
      case 'transfer':
        return 'Transfer Update';
      default:
        return 'Notification';
    }
  }
}

// ─── Sender + body card ──────────────────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF059669),
                  child: Text(
                    _initials(notification.sentByName),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.sentByName.isNotEmpty
                            ? notification.sentByName
                            : 'System',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a')
                            .format(notification.createdAt),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                _TypeBadge(type: notification.notifType),
              ],
            ),
            const Divider(height: 24),
            Text(
              notification.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              notification.body,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade800, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final cfg = _styleFor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        cfg.label,
        style: TextStyle(
          color: cfg.fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  _BadgeCfg _styleFor(String t) {
    switch (t) {
      case 'event_rsvp':
        return _BadgeCfg('EVENT', Colors.blue.shade50, Colors.blue.shade700);
      case 'announcement':
        return _BadgeCfg(
            'ANNOUNCEMENT', Colors.purple.shade50, Colors.purple.shade700);
      case 'contribution':
        return _BadgeCfg(
            'CONTRIBUTION', Colors.amber.shade50, Colors.amber.shade800);
      case 'transfer':
        return _BadgeCfg(
            'TRANSFER', Colors.orange.shade50, Colors.orange.shade700);
      default:
        return _BadgeCfg('INFO', Colors.grey.shade100, Colors.grey.shade700);
    }
  }
}

class _BadgeCfg {
  final String label;
  final Color bg;
  final Color fg;
  _BadgeCfg(this.label, this.bg, this.fg);
}

// ─── Response form ───────────────────────────────────────────────────────────
class _ResponseForm extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onSubmit;

  const _ResponseForm({
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NotificationController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Response',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map((o) => _ResponseOptionButton(
                    label: o,
                    selected: selected == o,
                    onTap: () => onSelect(o),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        Obx(() {
          final loading = ctrl.isLoading.value;
          final disabled = selected == null || loading;
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: disabled ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF047857),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor:
                    const Color(0xFF047857).withOpacity(0.4),
              ),
              child: loading
                  ? const ButtonLoader()
                  : const Text(
                      'Submit Response',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          );
        }),
      ],
    );
  }
}

class _ResponseOptionButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ResponseOptionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(label);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              selected ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.circle,
              size: 14,
              color: selected ? color : Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.grey.shade700,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(String label) {
    final l = label.toLowerCase();
    if (l == 'yes' || l == 'confirm' || l == 'attending') {
      return Colors.green.shade700;
    }
    if (l == 'no' || l == 'decline' || l == 'cannot') {
      return Colors.red.shade700;
    }
    if (l == 'maybe') return Colors.amber.shade800;
    return const Color(0xFF047857);
  }
}

// ─── Already-responded view ──────────────────────────────────────────────────
class _RespondedView extends StatelessWidget {
  final NotificationResponseModel response;
  const _RespondedView({required this.response});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            FaIcon(FontAwesomeIcons.circleCheck,
                size: 20, color: Colors.green.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You responded: ${response.response}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a')
                        .format(response.respondedAt),
                    style:
                        TextStyle(fontSize: 11, color: Colors.green.shade800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
