import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/models/seat_booking_model.dart';
import '../../core/models/transport_model.dart';
import '../../core/widgets/glass_card.dart';
import 'seat_booking_controller.dart';
import 'vehicle_top_view.dart';

class SeatMapScreen extends StatelessWidget {
  final TransportModel transport;

  const SeatMapScreen({super.key, required this.transport});

  @override
  Widget build(BuildContext context) {
    // Init controller and start live stream
    final ctrl = Get.put(SeatBookingController());
    ctrl.transportId = transport.id;
    ctrl.vehicleType = transport.vehicleType;
    ctrl.startListening();

    final auth = Get.find<AuthController>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronLeft,
              color: Colors.white, size: 16),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transport.vehicleLabel,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text(transport.driverName,
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withOpacity(0.6))),
          ],
        ),
        actions: [
          // Admin-only seat manifest sheet trigger
          if (auth.isSupervisorOrLeader)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.listCheck,
                  color: Colors.white70, size: 16),
              onPressed: () => _showManifestSheet(context, ctrl),
              tooltip: 'Seat Manifest',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0C0A09),
              Color(0xFF047857),
              Color(0xFF0891B2),
              Color(0xFF047857),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            if (!ctrl.hasLoaded.value) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF059669)),
              );
            }

            // Check if transport data is available
            if (transport.id.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Transport Not Found',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please contact your supervisor to set up transport data.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            }

            return _buildBody(context, ctrl, auth);
          }),
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, SeatBookingController ctrl, AuthController auth) {
    return Column(
      children: [
        // ── Stats bar ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _StatsBar(ctrl: ctrl),
        ),
        const SizedBox(height: 12),

        // ── Legend ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _Legend(),
        ),
        const SizedBox(height: 16),

        // ── Vehicle top view ───────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: VehicleTopView(ctrl: ctrl),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Seat manifest (mini) ───────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _MiniManifest(ctrl: ctrl),
                ),
                const SizedBox(height: 100), // space for bottom bar
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Confirm / Release bottom bar ────────────────────────
  // (shown as persistent bottom widget via Stack in real impl,
  //  here using bottomSheet pattern)
  void _showConfirmBar(BuildContext context, SeatBookingController ctrl) {
    // Called from VehicleTopView on seat tap — bottom sheet
    final selected = ctrl.selectedSeatId.value;
    if (selected.isEmpty) return;

    Get.bottomSheet(
      _ConfirmBookingSheet(ctrl: ctrl, seatId: selected),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  void _showManifestSheet(BuildContext context, SeatBookingController ctrl) {
    Get.bottomSheet(
      _AdminManifestSheet(ctrl: ctrl),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Stats bar — booked / available / vehicle type
// ─────────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final SeatBookingController ctrl;
  const _StatsBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Stat(
            label: 'Booked',
            value: '${ctrl.bookedCount}',
            color: const Color(0xFFCE93D8)),
        const SizedBox(width: 8),
        _Stat(
            label: 'Available',
            value: '${ctrl.availableCount}',
            color: const Color(0xFF059669)),
        const SizedBox(width: 8),
        _Stat(
            label: 'Total',
            value: '${ctrl.vehicleType.passengerCount}',
            color: Colors.white54),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Legend
// ─────────────────────────────────────────────────────────
class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _LegendItem(
              color: Color(0xFF047857),
              border: Color(0xFF059669),
              label: 'Available'),
          _LegendItem(
              color: Color(0xFF00897B),
              border: Color(0xFF26C6DA),
              label: 'Mine'),
          _LegendItem(
              color: Color(0xFF7B1FA2),
              border: Color(0xFFCE93D8),
              label: 'Booked'),
          _LegendItem(
              color: Color(0xFF1976D2),
              border: Color(0xFF40C4FF),
              label: 'Selected'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color, border;
  final String label;
  const _LegendItem(
      {required this.color, required this.border, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: border, width: 1.2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Mini manifest list under the vehicle view
// ─────────────────────────────────────────────────────────
class _MiniManifest extends StatelessWidget {
  final SeatBookingController ctrl;
  const _MiniManifest({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final passengerSeats =
        ctrl.vehicleType.layout.where((s) => !s.isDriver).toList();

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.listCheck,
                  size: 12, color: Color(0xFF059669)),
              const SizedBox(width: 8),
              const Text('Seat Manifest',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const Spacer(),
              Text('${ctrl.bookedCount}/${ctrl.vehicleType.passengerCount}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          ...passengerSeats.map((seat) {
            final booking = ctrl.bookings[seat.id];
            final isMe = booking?.userId == auth.uid;
            return _ManifestRow(
              seatId: seat.id,
              booking: booking,
              isMe: isMe,
              onRelease: (isMe && ctrl.iHaveASeat)
                  ? () => _confirmRelease(context, ctrl)
                  : null,
            );
          }),
        ],
      ),
    );
  }

  void _confirmRelease(BuildContext context, SeatBookingController ctrl) {
    Get.defaultDialog(
      title: 'Release Seat?',
      middleText: 'Are you sure you want to give up your seat?',
      textConfirm: 'Release',
      textCancel: 'Keep It',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red.shade700,
      onConfirm: () {
        Get.back();
        ctrl.releaseSeat();
      },
    );
  }
}

class _ManifestRow extends StatelessWidget {
  final String seatId;
  final SeatBookingModel? booking;
  final bool isMe;
  final VoidCallback? onRelease;

  const _ManifestRow({
    required this.seatId,
    required this.booking,
    required this.isMe,
    this.onRelease,
  });

  @override
  Widget build(BuildContext context) {
    final isBooked = booking != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMe
            ? const Color(0xFF00897B).withOpacity(0.15)
            : isBooked
                ? const Color(0xFF7B1FA2).withOpacity(0.1)
                : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMe
              ? const Color(0xFF26C6DA).withOpacity(0.4)
              : isBooked
                  ? const Color(0xFFCE93D8).withOpacity(0.3)
                  : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          // Seat ID chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: isMe
                  ? const Color(0xFF00897B).withOpacity(0.3)
                  : isBooked
                      ? const Color(0xFF7B1FA2).withOpacity(0.3)
                      : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(seatId,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isMe
                        ? const Color(0xFF26C6DA)
                        : isBooked
                            ? const Color(0xFFCE93D8)
                            : Colors.white38)),
          ),
          const SizedBox(width: 10),

          // Avatar + Name
          if (isBooked) ...[
            if (booking!.avatarUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: booking!.avatarUrl,
                imageBuilder: (_, img) =>
                    CircleAvatar(radius: 12, backgroundImage: img),
                placeholder: (_, __) =>
                    _InitialAvatar(name: booking!.displayName, radius: 12),
                errorWidget: (_, __, ___) =>
                    _InitialAvatar(name: booking!.displayName, radius: 12),
              )
            else
              _InitialAvatar(name: booking!.displayName, radius: 12),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isMe ? '${booking!.displayName} (You)' : booking!.displayName,
                style: TextStyle(
                    color: isMe ? const Color(0xFF80CBC4) : Colors.white70,
                    fontSize: 12,
                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isMe && onRelease != null)
              GestureDetector(
                onTap: onRelease,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.red.withOpacity(0.4)),
                  ),
                  child: const Text('Release',
                      style: TextStyle(color: Colors.redAccent, fontSize: 10)),
                ),
              ),
          ] else
            Expanded(
              child: Text('Available',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3), fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Confirm booking bottom sheet
// ─────────────────────────────────────────────────────────
class _ConfirmBookingSheet extends StatelessWidget {
  final SeatBookingController ctrl;
  final String seatId;

  const _ConfirmBookingSheet({required this.ctrl, required this.seatId});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0C0A09).withOpacity(0.95),
                const Color(0xFF047857).withOpacity(0.95),
              ],
            ),
            border: const Border(
              top: BorderSide(color: Color(0xFF059669), width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const FaIcon(FontAwesomeIcons.chair,
                  color: Color(0xFF059669), size: 32),
              const SizedBox(height: 12),
              Text('Confirm Seat $seatId',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                'This seat will be reserved for you.\nOne seat per person only.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: ctrl.isLoading.value
                          ? null
                          : () async {
                              await ctrl.confirmBooking();
                              Get.back();
                            },
                      icon: ctrl.isLoading.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const FaIcon(FontAwesomeIcons.check, size: 14),
                      label: const Text('Book This Seat',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  )),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ctrl.selectedSeatId.value = '';
                    Get.back();
                  },
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white54)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Admin: full seat manifest sheet
// ─────────────────────────────────────────────────────────
class _AdminManifestSheet extends StatelessWidget {
  final SeatBookingController ctrl;
  const _AdminManifestSheet({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0C0A09).withOpacity(0.97),
                const Color(0xFF047857).withOpacity(0.97),
              ],
            ),
            border: const Border(
                top: BorderSide(color: Color(0xFF7B1FA2), width: 1)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.clipboardList,
                        color: Color(0xFFCE93D8), size: 16),
                    const SizedBox(width: 8),
                    const Text('Seat Manifest',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const Spacer(),
                    Obx(() => Text(
                          '${ctrl.bookedCount}/${ctrl.vehicleType.passengerCount} booked',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        )),
                  ],
                ),
              ),
              const Divider(color: Colors.white12),
              // List
              Expanded(
                child: Obx(() {
                  final booked = ctrl.bookings.entries.toList()
                    ..sort(
                        (a, b) => a.value.bookedAt.compareTo(b.value.bookedAt));
                  if (booked.isEmpty) {
                    return const Center(
                        child: Text('No bookings yet.',
                            style: TextStyle(color: Colors.white38)));
                  }
                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: booked.length,
                    itemBuilder: (_, i) {
                      final entry = booked[i];
                      return _AdminManifestRow(
                        seatId: entry.key,
                        booking: entry.value,
                        onRelease: () => ctrl.adminRelease(entry.key),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminManifestRow extends StatelessWidget {
  final String seatId;
  final SeatBookingModel booking;
  final VoidCallback onRelease;

  const _AdminManifestRow({
    required this.seatId,
    required this.booking,
    required this.onRelease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF7B1FA2).withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(seatId,
                style: const TextStyle(
                    color: Color(0xFFCE93D8),
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          const SizedBox(width: 10),
          _InitialAvatar(name: booking.displayName, radius: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                Text(
                    '${booking.bookedAt.hour.toString().padLeft(2, '0')}:${booking.bookedAt.minute.toString().padLeft(2, '0')}',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Get.defaultDialog(
              title: 'Force Release?',
              middleText: 'Release seat $seatId from ${booking.displayName}?',
              textConfirm: 'Release',
              textCancel: 'Cancel',
              buttonColor: Colors.red.shade700,
              confirmTextColor: Colors.white,
              onConfirm: () {
                Get.back();
                onRelease();
              },
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withOpacity(0.35)),
              ),
              child: const Text('Release',
                  style: TextStyle(color: Colors.redAccent, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Helper: Initials avatar
// ─────────────────────────────────────────────────────────
class _InitialAvatar extends StatelessWidget {
  final String name;
  final double radius;
  const _InitialAvatar({required this.name, required this.radius});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF00897B).withOpacity(0.3),
      child: Text(initials,
          style: TextStyle(
              color: const Color(0xFF26C6DA),
              fontSize: radius * 0.75,
              fontWeight: FontWeight.bold)),
    );
  }
}
