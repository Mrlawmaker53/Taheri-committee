import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/models/event_model.dart';
import '../../../core/models/vehicle_model.dart';
import '../../../core/theme/app_tokens.dart';
import 'booking_controller.dart';

class TransportBookingScreen extends StatefulWidget {
  final EventModel event;
  const TransportBookingScreen({super.key, required this.event});

  @override
  State<TransportBookingScreen> createState() => _TransportBookingScreenState();
}

class _TransportBookingScreenState extends State<TransportBookingScreen> {
  late final BookingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(BookingController());
    _ctrl.initForEvent(widget.event);
  }

  @override
  void dispose() {
    Get.delete<BookingController>();
    super.dispose();
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
        title: Text(widget.event.title),
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value && !_ctrl.hasLoaded.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // If user already has a booking, show booking details
        if (_ctrl.myBooking.value != null) {
          return _BookingConfirmedView(
            ctrl: _ctrl,
            event: widget.event,
            isDark: isDark,
          );
        }

        // Otherwise show vehicle list
        return _VehicleListView(
          ctrl: _ctrl,
          event: widget.event,
          isDark: isDark,
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BOOKING CONFIRMED VIEW
// ═══════════════════════════════════════════════════════════════════════════════
class _BookingConfirmedView extends StatelessWidget {
  final BookingController ctrl;
  final EventModel event;
  final bool isDark;

  const _BookingConfirmedView({
    required this.ctrl,
    required this.event,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final booking = ctrl.myBooking.value!;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Success icon ─────────────────────────────────────────
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppTokens.primarySubtle,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 56,
                color: AppTokens.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Booking Confirmed!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppTokens.darkTextPrimary : AppTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your seat has been booked successfully',
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? AppTokens.darkTextSecondary
                    : AppTokens.textSecondary,
              ),
            ),
            const SizedBox(height: 28),

            // ── Booking details card ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTokens.darkCard : AppTokens.surfaceCard,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(
                    color: isDark ? AppTokens.darkBorder : AppTokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Booking Code', booking.bookingCode, true),
                  const Divider(height: 24),
                  _detailRow('Event', event.title, false),
                  const SizedBox(height: 10),
                  _detailRow('Team',
                      booking.teamName.isEmpty ? '—' : booking.teamName, false),
                  const SizedBox(height: 10),
                  _detailRow(
                    'Booked On',
                    DateFormat('dd MMM yyyy, hh:mm a').format(booking.bookedAt),
                    false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── QR placeholder card ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTokens.darkCard : AppTokens.surfaceCard,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(
                    color: isDark ? AppTokens.darkBorder : AppTokens.border),
              ),
              child: Column(
                children: [
                  Text(
                    'Show this code on event day',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTokens.darkTextSecondary
                          : AppTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTokens.darkSurface
                          : AppTokens.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(FontAwesomeIcons.qrcode,
                              size: 48, color: AppTokens.primary),
                          const SizedBox(height: 12),
                          Text(
                            booking.qrCode,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTokens.primary,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Cancel button ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: Obx(() => OutlinedButton(
                    onPressed: ctrl.isBooking.value
                        ? null
                        : () => _confirmCancel(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTokens.danger,
                      side: const BorderSide(color: AppTokens.danger, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusButton),
                      ),
                    ),
                    child: ctrl.isBooking.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTokens.danger))
                        : const Text('Cancel Booking',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  )),
            ),
          ],
        ),
      );
    });
  }

  Widget _detailRow(String label, String value, bool highlight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTokens.darkTextSecondary
                    : AppTokens.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: highlight ? 18 : 15,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
              color: highlight
                  ? AppTokens.primary
                  : (isDark
                      ? AppTokens.darkTextPrimary
                      : AppTokens.textPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content:
            const Text('Are you sure you want to cancel your seat booking?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No, Keep It')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.danger,
                foregroundColor: Colors.white),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirmed == true) await ctrl.cancelBooking();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VEHICLE LIST VIEW
// ═══════════════════════════════════════════════════════════════════════════════
class _VehicleListView extends StatelessWidget {
  final BookingController ctrl;
  final EventModel event;
  final bool isDark;

  const _VehicleListView({
    required this.ctrl,
    required this.event,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final vehicles = ctrl.vehicles;

      if (vehicles.isEmpty) {
        return _emptyState();
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vehicles.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) return _header();
          return _VehicleCard(
            vehicle: vehicles[index - 1],
            ctrl: ctrl,
            isDark: isDark,
          );
        },
      );
    });
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Transport',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTokens.darkTextPrimary : AppTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a vehicle to book your seat',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppTokens.darkTextSecondary
                  : AppTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.bus,
              size: 64,
              color: isDark ? AppTokens.darkTextMuted : AppTokens.textMuted),
          const SizedBox(height: 16),
          Text(
            'No vehicles available yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTokens.darkTextPrimary : AppTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Transport details will be added soon',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppTokens.darkTextSecondary
                  : AppTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VEHICLE CARD
// ═══════════════════════════════════════════════════════════════════════════════
class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final BookingController ctrl;
  final bool isDark;

  const _VehicleCard({
    required this.vehicle,
    required this.ctrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasSeats = vehicle.hasSeats;
    final rate = vehicle.occupancyRate / 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTokens.darkCard : AppTokens.surfaceCard,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(
          color: hasSeats
              ? AppTokens.primary.withOpacity(0.4)
              : (isDark ? AppTokens.darkBorder : AppTokens.border),
          width: hasSeats ? 2 : 1,
        ),
        boxShadow: isDark ? null : AppTokens.shadowXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTokens.primarySubtle,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                ),
                child: const Icon(Icons.directions_bus_rounded,
                    color: AppTokens.primary, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTokens.darkTextPrimary
                            : AppTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTokens.secondaryLight,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusChip),
                      ),
                      child: Text(
                        vehicle.type,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTokens.secondaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Info rows ──────────────────────────────────────────────
          _infoRow(Icons.access_time_rounded,
              'Departure: ${DateFormat('hh:mm a').format(vehicle.departureTime)}'),
          if (vehicle.route != null && vehicle.route!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.route_rounded, vehicle.route!),
          ],
          if (vehicle.driverName != null && vehicle.driverName!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.person_rounded, 'Driver: ${vehicle.driverName}'),
          ],
          const SizedBox(height: 16),

          // ── Seat progress ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${vehicle.availableSeats} seats left',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: hasSeats ? AppTokens.primary : AppTokens.danger,
                ),
              ),
              Text(
                '${vehicle.bookedSeats}/${vehicle.totalSeats}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppTokens.darkTextSecondary
                      : AppTokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate.clamp(0.0, 1.0),
              backgroundColor: isDark ? AppTokens.darkBorder : AppTokens.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                hasSeats ? AppTokens.primary : AppTokens.danger,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),

          // ── Book button ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: Obx(() => ElevatedButton(
                  onPressed: hasSeats && !ctrl.isBooking.value
                      ? () => _confirmBook(context)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.primary,
                    disabledBackgroundColor:
                        isDark ? AppTokens.darkBorder : AppTokens.textMuted,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusButton),
                    ),
                  ),
                  child: ctrl.isBooking.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          hasSeats ? 'Book Seat' : 'Fully Booked',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                )),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTokens.textSecondary),
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

  Future<void> _confirmBook(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Text('Book a seat on ${vehicle.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.primary,
                foregroundColor: Colors.white),
            child: const Text('Book Seat'),
          ),
        ],
      ),
    );
    if (confirmed == true) await ctrl.bookSeat(vehicle.id);
  }
}
