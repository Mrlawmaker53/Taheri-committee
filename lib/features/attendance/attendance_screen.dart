import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/event_model.dart';
import 'attendance_controller.dart';
import 'qr_scanner_screen.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AttendanceController(), permanent: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        automaticallyImplyLeading: false,
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return RefreshIndicator(
            onRefresh: ctrl.refresh,
            child: ListView(
              padding: EdgeInsets.all(padding),
              children: [
                const _ScanCtaCard(),
                const SizedBox(height: 20),
                Text('My Attendance History',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Obx(() {
                  if (ctrl.myAttendance.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(FontAwesomeIcons.calendarXmark,
                                size: 56, color: Colors.white24),
                            SizedBox(height: 16),
                            Text('No attendance records yet',
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500)),
                            SizedBox(height: 6),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Attend an event and scan the QR code.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: ctrl.myAttendance
                        .map((a) => _AttendanceHistoryCard(
                              eventId: a.eventId,
                              scannedAt: a.scannedAt,
                              method: a.method,
                            ))
                        .toList(),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScanCtaCard extends StatefulWidget {
  const _ScanCtaCard();

  @override
  State<_ScanCtaCard> createState() => _ScanCtaCardState();
}

class _ScanCtaCardState extends State<_ScanCtaCard> {
  bool _pressed = false;

  void _setPressed(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: () => Get.to(() => const QrScannerScreen()),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF006080), Color(0xFF0097A7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF059669).withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FaIcon(FontAwesomeIcons.qrcode,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scan Event QR Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mark your attendance at an event',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const FaIcon(FontAwesomeIcons.chevronRight,
                  color: Colors.white70, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceHistoryCard extends StatelessWidget {
  final String eventId;
  final DateTime scannedAt;
  final String method;

  const _AttendanceHistoryCard({
    required this.eventId,
    required this.scannedAt,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    final isQr = method == 'qr';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF4CAF50).withOpacity(0.3),
            ),
          ),
          child: const FaIcon(FontAwesomeIcons.circleCheck,
              color: Color(0xFF81C784), size: 18),
        ),
        title: FutureBuilder<EventModel?>(
          future: _fetchEvent(eventId),
          builder: (ctx, snap) {
            final title = snap.data?.title ?? 'Loading…';
            return Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14));
          },
        ),
        subtitle: Text(
          DateFormat('dd MMM yyyy, hh:mm a').format(scannedAt),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isQr
                ? const Color(0xFF059669).withOpacity(0.12)
                : const Color(0xFFD97706).withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isQr
                  ? const Color(0xFF059669).withOpacity(0.3)
                  : const Color(0xFFD97706).withOpacity(0.4),
            ),
          ),
          child: Text(
            isQr ? 'QR Scan' : 'Manual',
            style: TextStyle(
              fontSize: 10,
              color: isQr ? const Color(0xFF059669) : const Color(0xFFFFD54F),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<EventModel?> _fetchEvent(String id) async {
    final doc = await FirestoreService.events.doc(id).get();
    if (!doc.exists) return null;
    return EventModel.fromFirestore(doc);
  }
}
