import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/models/new_seat_booking_model.dart';
import '../../../core/theme/app_tokens.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Stream<List<NewSeatBookingModel>> _bookingsStream(String? statusFilter) {
    final uid = Get.find<AuthController>().uid;
    if (uid.isEmpty) return const Stream.empty();

    Query query = _db
        .collection('seatBookings')
        .where('userId', isEqualTo: uid)
        .orderBy('bookedAt', descending: true);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots().map((snap) =>
        snap.docs.map((d) => NewSeatBookingModel.fromFirestore(d)).toList());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: 16),
          onPressed: () => Get.back(),
        ),
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTokens.primary,
          labelColor: isDark ? AppTokens.darkTextPrimary : AppTokens.primary,
          unselectedLabelColor:
              isDark ? AppTokens.darkTextMuted : AppTokens.textSecondary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _BookingsList(
            stream: _bookingsStream('confirmed'),
            emptyIcon: FontAwesomeIcons.calendarCheck,
            emptyTitle: 'No upcoming bookings',
            emptySubtitle: 'Book transport from an event page',
            filterUpcoming: true,
            isDark: isDark,
          ),
          _BookingsList(
            stream: _bookingsStream('confirmed'),
            emptyIcon: FontAwesomeIcons.clockRotateLeft,
            emptyTitle: 'No past bookings',
            emptySubtitle: 'Your completed trips will appear here',
            filterUpcoming: false,
            isDark: isDark,
          ),
          _BookingsList(
            stream: _bookingsStream('cancelled'),
            emptyIcon: FontAwesomeIcons.ban,
            emptyTitle: 'No cancelled bookings',
            emptySubtitle: 'Cancelled bookings will appear here',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BOOKINGS LIST
// ═══════════════════════════════════════════════════════════════════════════════
class _BookingsList extends StatelessWidget {
  final Stream<List<NewSeatBookingModel>> stream;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final bool? filterUpcoming; // true = future, false = past, null = all
  final bool isDark;

  const _BookingsList({
    required this.stream,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.filterUpcoming,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NewSeatBookingModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var bookings = snapshot.data ?? [];

        // Filter by upcoming/past based on bookedAt (simple heuristic)
        // In production you'd compare against the event date
        if (filterUpcoming == true) {
          bookings = bookings
              .where((b) =>
                  b.bookedAt.isAfter(DateTime.now().subtract(const Duration(days: 1))))
              .toList();
        } else if (filterUpcoming == false) {
          bookings = bookings
              .where((b) =>
                  b.bookedAt.isBefore(DateTime.now().subtract(const Duration(days: 1))))
              .toList();
        }

        if (bookings.isEmpty) {
          return _emptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (_, i) => _BookingCard(
            booking: bookings[i],
            isDark: isDark,
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(emptyIcon,
              size: 56,
              color: isDark ? AppTokens.darkTextMuted : AppTokens.textMuted),
          const SizedBox(height: 16),
          Text(emptyTitle,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppTokens.darkTextPrimary
                      : AppTokens.textPrimary)),
          const SizedBox(height: 6),
          Text(emptySubtitle,
              style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppTokens.darkTextSecondary
                      : AppTokens.textSecondary)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BOOKING CARD
// ═══════════════════════════════════════════════════════════════════════════════
class _BookingCard extends StatelessWidget {
  final NewSeatBookingModel booking;
  final bool isDark;

  const _BookingCard({required this.booking, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isCancelled = booking.status == 'cancelled';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTokens.darkCard : AppTokens.surfaceCard,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(
            color: isDark ? AppTokens.darkBorder : AppTokens.border),
        boxShadow: isDark ? null : AppTokens.shadowXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: booking code + status badge ─────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking.bookingCode,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCancelled
                      ? AppTokens.textMuted
                      : AppTokens.primary,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? AppTokens.danger.withOpacity(0.1)
                      : AppTokens.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                ),
                child: Text(
                  booking.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isCancelled ? AppTokens.danger : AppTokens.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Details ──────────────────────────────────────────────
          _detailRow(
            Icons.calendar_today_rounded,
            'Booked: ${DateFormat('dd MMM yyyy, hh:mm a').format(booking.bookedAt)}',
          ),
          if (booking.teamName.isNotEmpty) ...[
            const SizedBox(height: 6),
            _detailRow(Icons.group_rounded, 'Team: ${booking.teamName}'),
          ],
          if (isCancelled && booking.cancelledAt != null) ...[
            const SizedBox(height: 6),
            _detailRow(
              Icons.cancel_outlined,
              'Cancelled: ${DateFormat('dd MMM yyyy').format(booking.cancelledAt!)}',
            ),
          ],

          // ── QR section (only for confirmed) ──────────────────────
          if (!isCancelled) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTokens.darkSurface
                    : AppTokens.surfaceElevated,
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.qrcode,
                      size: 28, color: AppTokens.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.qrCode,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTokens.primary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Show this code on event day',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppTokens.darkTextMuted
                                : AppTokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon,
            size: 14,
            color:
                isDark ? AppTokens.darkTextMuted : AppTokens.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppTokens.darkTextSecondary
                  : AppTokens.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
