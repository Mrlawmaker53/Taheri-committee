import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/vehicle_layouts.dart';
import '../../../../core/controllers/auth_controller.dart';
import '../domain/event_model.dart';
import '../domain/booking_model.dart';
import 'widgets/vehicle_top_view.dart';
import '../data/booking_repository.dart';

class SeatMapScreen extends StatefulWidget {
  final EventModel event;
  const SeatMapScreen({super.key, required this.event});

  @override
  State<SeatMapScreen> createState() => _SeatMapScreenState();
}

class _SeatMapScreenState extends State<SeatMapScreen> {
  final BookingRepository _bookingRepo = BookingRepository();
  String? _selectedSeatId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.event.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: 'Seat manifest',
            onPressed: () => _showManifest(context),
          ),
        ],
      ),
      body: StreamBuilder<Map<String, BookingModel>>(
        stream: _bookingRepo.watchBookings(widget.event.id),
        initialData: const {},
        builder: (context, snapshot) {
          final bookings = snapshot.data!;

          final myBookedSeat = bookings.entries
              .where((e) => e.value.userId == auth.uid)
              .map((e) => e.key)
              .firstOrNull;

          return Column(
            children: [
              // Event info bar
              _EventInfoBar(event: widget.event, bookedCount: bookings.length),

              // Legend
              _SeatLegend(myBookedSeat: myBookedSeat),

              // Vehicle top-view (main)
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: VehicleTopView(
                    vehicleType: widget.event.vehicleType,
                    bookings: bookings,
                    currentUserId: auth.uid,
                    selectedSeatId: _selectedSeatId,
                    onSeatTap: (seatId) => _handleSeatTap(
                        context, seatId, bookings, auth.uid, myBookedSeat),
                  ),
                ),
              ),

              // Bottom action bar
              _BottomBar(
                selectedSeat: _selectedSeatId,
                myBookedSeat: myBookedSeat,
                isLoading: _isLoading,
                onConfirm: () => _confirmBooking(),
                onRelease: () => _releaseSeat(myBookedSeat!),
                onClearSelection: () => setState(() => _selectedSeatId = null),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleSeatTap(
    BuildContext context,
    String seatId,
    Map<String, BookingModel> bookings,
    String uid,
    String? myBookedSeat,
  ) {
    // Driver seat — ignore
    final layout = vehicleLayouts[widget.event.vehicleType]!;
    final seat = layout.firstWhere((s) => s['id'] == seatId);
    if (seat['type'] == 'driver') return;

    final booking = bookings[seatId];

    // Tapped own seat — no action
    if (booking != null && booking.userId == uid) return;

    // Tapped someone else's seat — show who
    if (booking != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Booked by ${booking.displayName}'),
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    // Already has a booking — warn
    if (myBookedSeat != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You already have a seat. Release it first.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Event is not open
    if (widget.event.status != 'open') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Booking is closed for this event.'),
      ));
      return;
    }

    // Available — select it
    setState(() => _selectedSeatId = seatId);

    // Show confirm bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingConfirmSheet(
        seatId: seatId,
        event: widget.event,
        onConfirm: () {
          Navigator.pop(context);
          _confirmBooking();
        },
        onCancel: () {
          Navigator.pop(context);
          setState(() => _selectedSeatId = null);
        },
      ),
    );
  }

  Future<void> _confirmBooking() async {
    if (_selectedSeatId == null) return;

    setState(() => _isLoading = true);
    try {
      await _bookingRepo.bookSeat(
        eventId: widget.event.id,
        seatId: _selectedSeatId!,
      );
      setState(() => _selectedSeatId = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seat booked! ✓'),
            backgroundColor: Color(0xFF1D9E75),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _releaseSeat(String seatId) async {
    setState(() => _isLoading = true);
    try {
      await _bookingRepo.releaseSeat(
        eventId: widget.event.id,
        seatId: seatId,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seat released successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showManifest(BuildContext context) {
    // TODO: Implement seat manifest
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seat manifest coming soon!')),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _EventInfoBar extends StatelessWidget {
  final EventModel event;
  final int bookedCount;
  const _EventInfoBar({required this.event, required this.bookedCount});

  @override
  Widget build(BuildContext context) {
    final left = event.totalSeats - bookedCount;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.departureLocation,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                Text('${event.departureTime} · ${event.destination}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:
                  left > 0 ? const Color(0xFFEAF3DE) : const Color(0xFFFCEBEB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              left > 0 ? '$left seats left' : 'Full',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: left > 0
                    ? const Color(0xFF3B6D11)
                    : const Color(0xFFA32D2D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  final String? myBookedSeat;
  const _SeatLegend({this.myBookedSeat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _dot(const Color(0xFFE6F1FB), const Color(0xFF378ADD)),
          const SizedBox(width: 4),
          Text('Available', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(width: 12),
          _dot(const Color(0xFF1D9E75), const Color(0xFF0F6E56)),
          const SizedBox(width: 4),
          Text('Mine', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(width: 12),
          _dot(const Color(0xFFF5C4B3), const Color(0xFFD85A30)),
          const SizedBox(width: 4),
          Text('Taken', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(width: 12),
          _dot(const Color(0xFFF7C1C1), const Color(0xFFE24B4A)),
          const SizedBox(width: 4),
          Text('Driver', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _dot(Color fill, Color border) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: border, width: 1.5),
        ),
      );
}

class _BottomBar extends StatelessWidget {
  final String? selectedSeat;
  final String? myBookedSeat;
  final bool isLoading;
  final VoidCallback onConfirm;
  final VoidCallback onRelease;
  final VoidCallback onClearSelection;

  const _BottomBar({
    required this.selectedSeat,
    required this.myBookedSeat,
    required this.isLoading,
    required this.onConfirm,
    required this.onRelease,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border:
              Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                myBookedSeat != null
                    ? 'Your seat: $myBookedSeat ✓'
                    : selectedSeat != null
                        ? 'Selected: $selectedSeat'
                        : 'Tap a seat to book',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (myBookedSeat != null)
              OutlinedButton(
                onPressed: isLoading ? null : onRelease,
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700),
                child: const Text('Release'),
              )
            else if (selectedSeat != null) ...[
              TextButton(
                  onPressed: onClearSelection, child: const Text('Cancel')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: isLoading ? null : onConfirm,
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookingConfirmSheet extends StatelessWidget {
  final String seatId;
  final EventModel event;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _BookingConfirmSheet({
    required this.seatId,
    required this.event,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Icon(Icons.event_seat_rounded,
              size: 40, color: Color(0xFF185FA5)),
          const SizedBox(height: 12),
          Text('Confirm Booking',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          _row(context, 'Event', event.title),
          _row(context, 'Seat', seatId),
          _row(context, 'Date',
              '${event.date.day}/${event.date.month}/${event.date.year}'),
          _row(context, 'Departure', event.departureTime),
          _row(context, 'From', event.departureLocation),
          _row(context, 'To', event.destination),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: onCancel, child: const Text('Cancel')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                    onPressed: onConfirm, child: const Text('Confirm Seat')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
                width: 90,
                child: Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey))),
            Expanded(
                child: Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500))),
          ],
        ),
      );
}
