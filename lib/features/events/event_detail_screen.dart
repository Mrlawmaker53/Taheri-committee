import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/models/event_model.dart';
import '../../core/theme/app_tokens.dart';
import '../seat_booking/presentation/transport_booking_screen.dart';
import '../seat_booking/presentation/admin_vehicle_screen.dart';
import 'events_controller.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<EventsController>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronLeft,
              color: Colors.white, size: 16),
          onPressed: () => Get.back(),
        ),
        title: const Text('Event Details'),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF047857), Color(0xFF1976D2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.calendar,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEEE, dd MMM yyyy • hh:mm a')
                                .format(event.eventDate),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.locationDot,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.location,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _InfoChip(
                        icon: FontAwesomeIcons.checkToSlot,
                        label: 'RSVP',
                        value: event.rsvpEnabled ? 'Open' : 'Closed',
                        color: event.rsvpEnabled ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoChip(
                        icon: FontAwesomeIcons.userCheck,
                        label: 'Attendance',
                        value: event.attendanceEnabled ? 'Enabled' : 'Disabled',
                        color:
                            event.attendanceEnabled ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (event.rsvpEnabled) ...[
                  Obx(() {
                    final status = ctrl.rsvpStatusFor(event.eventId);
                    return _RsvpSection(
                        eventId: event.eventId,
                        currentStatus: status,
                        ctrl: ctrl);
                  }),
                  const SizedBox(height: 24),
                ],
                // ── Transport booking buttons ─────────────────────────
                if (event.transportRequired) ...[
                  _InfoChip(
                    icon: FontAwesomeIcons.bus,
                    label: 'Transport',
                    value: event.transportStatus == 'active'
                        ? 'Available'
                        : 'Planning',
                    color: event.transportStatus == 'active'
                        ? AppTokens.primary
                        : AppTokens.warning,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Get.to(() => TransportBookingScreen(event: event)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const FaIcon(FontAwesomeIcons.bus, size: 16),
                      label: const Text('Book Transport',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Admin: manage vehicles
                if (Get.find<AuthController>().isSupervisorOrLeader) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Get.to(() => AdminVehicleScreen(event: event)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTokens.primary,
                        side: const BorderSide(color: AppTokens.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const FaIcon(FontAwesomeIcons.gears, size: 16),
                      label: const Text('Manage Transport',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (Get.find<AuthController>().isSupervisorOrLeader &&
                    event.attendanceEnabled)
                  _AttendanceQrButton(event: event),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AttendanceQrButton extends StatelessWidget {
  final EventModel event;
  const _AttendanceQrButton({required this.event});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF047857),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const FaIcon(FontAwesomeIcons.qrcode, size: 16),
        label: const Text(
          'Show Attendance QR',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        onPressed: () => _showQrDialog(context),
      ),
    );
  }

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.qrcode,
                        color: Color(0xFF047857), size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Attendance QR',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const FaIcon(FontAwesomeIcons.xmark, size: 16),
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: QrImageView(
                    data: event.eventId,
                    version: QrVersions.auto,
                    size: 280,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF047857),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF047857),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  event.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, dd MMM yyyy • hh:mm a')
                      .format(event.eventDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(FontAwesomeIcons.circleInfo,
                          size: 12, color: Color(0xFF047857)),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Members scan this QR to mark attendance',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF047857)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close'),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            FaIcon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  Text(value,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RsvpSection extends StatelessWidget {
  final String eventId;
  final String? currentStatus;
  final EventsController ctrl;

  const _RsvpSection({
    required this.eventId,
    required this.currentStatus,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your RSVP',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => ctrl.submitRsvp(eventId, 'attending'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      currentStatus == 'attending' ? Colors.green : null,
                ),
                icon: const FaIcon(FontAwesomeIcons.check, size: 14),
                label: const Text('Attending'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => ctrl.submitRsvp(eventId, 'not_attending'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentStatus == 'not_attending'
                      ? Colors.red
                      : Colors.grey,
                ),
                icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
                label: const Text('Not Attending'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
