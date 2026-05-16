import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/models/event_model.dart';
import '../../../core/models/vehicle_model.dart';
import '../../../core/models/new_seat_booking_model.dart';
import '../../../core/theme/app_tokens.dart';
import 'booking_controller.dart';
import 'booking_scanner_screen.dart';

class AdminVehicleScreen extends StatefulWidget {
  final EventModel event;
  const AdminVehicleScreen({super.key, required this.event});

  @override
  State<AdminVehicleScreen> createState() => _AdminVehicleScreenState();
}

class _AdminVehicleScreenState extends State<AdminVehicleScreen> {
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
        title: const Text('Manage Transport'),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.qrcode, size: 18),
            tooltip: 'Verify Bookings',
            onPressed: () => Get.to(() => BookingScannerScreen(
                  eventId: widget.event.eventId,
                  eventTitle: widget.event.title,
                )),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.chartBar, size: 18),
            tooltip: 'Booking Report',
            onPressed: () => _showReportSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateVehicleSheet(context),
        backgroundColor: AppTokens.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value && !_ctrl.hasLoaded.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final vehicles = _ctrl.vehicles;

        if (vehicles.isEmpty) {
          return _emptyState(isDark, context);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: vehicles.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _statsHeader(isDark);
            return _AdminVehicleCard(
              vehicle: vehicles[index - 1],
              bookings: _ctrl.bookingsForVehicle(vehicles[index - 1].id),
              ctrl: _ctrl,
              isDark: isDark,
            );
          },
        );
      }),
    );
  }

  Widget _statsHeader(bool isDark) {
    return Obx(() {
      final vehicles = _ctrl.vehicles;
      int totalSeats = 0;
      int bookedSeats = 0;
      for (final v in vehicles) {
        totalSeats += v.totalSeats;
        bookedSeats += v.bookedSeats;
      }
      final available = totalSeats - bookedSeats;
      final rate = totalSeats > 0
          ? (bookedSeats / totalSeats * 100).toStringAsFixed(0)
          : '0';

      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTokens.heroGradient,
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy').format(widget.event.eventDate),
              style:
                  TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _statChip(
                    'Vehicles', '${vehicles.length}', Icons.directions_bus),
                const SizedBox(width: 12),
                _statChip(
                    'Booked', '$bookedSeats/$totalSeats', Icons.event_seat),
                const SizedBox(width: 12),
                _statChip(
                    'Available', '$available', Icons.check_circle_outline),
                const SizedBox(width: 12),
                _statChip('Rate', '$rate%', Icons.pie_chart_outline),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _statChip(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(bool isDark, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.bus,
              size: 64,
              color: isDark ? AppTokens.darkTextMuted : AppTokens.textMuted),
          const SizedBox(height: 16),
          Text('No vehicles added yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppTokens.darkTextPrimary
                      : AppTokens.textPrimary)),
          const SizedBox(height: 6),
          Text('Add vehicles for this event',
              style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppTokens.darkTextSecondary
                      : AppTokens.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showCreateVehicleSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Vehicle'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.primary,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  // ── Create Vehicle Bottom Sheet ──────────────────────────────────────
  void _showCreateVehicleSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final routeCtrl = TextEditingController();
    final driverNameCtrl = TextEditingController();
    final driverMobileCtrl = TextEditingController();
    final selectedType = 'Land Cruiser'.obs;
    final totalSeats = 11.obs;
    final departureTime =
        Rx<DateTime>(widget.event.eventDate.subtract(const Duration(hours: 1)));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTokens.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Add Vehicle',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Vehicle name
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Name *',
                  hintText: 'e.g., Toyota Cruiser - Main',
                  prefixIcon: Icon(Icons.directions_bus),
                ),
              ),
              const SizedBox(height: 16),

              // Vehicle type dropdown
              Obx(() => DropdownButtonFormField<String>(
                    initialValue: selectedType.value,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Type *',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: VehicleModel.vehicleTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        selectedType.value = val;
                        totalSeats.value =
                            VehicleModel.defaultSeatsForType(val);
                      }
                    },
                  )),
              const SizedBox(height: 16),

              // Total seats
              Obx(() => TextFormField(
                    initialValue: totalSeats.value.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total Seats *',
                      prefixIcon: Icon(Icons.event_seat),
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n > 0) totalSeats.value = n;
                    },
                  )),
              const SizedBox(height: 16),

              // Departure time
              Obx(() => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time),
                    title: const Text('Departure Time'),
                    subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a')
                        .format(departureTime.value)),
                    trailing: const Icon(Icons.edit, color: AppTokens.primary),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: departureTime.value,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime:
                            TimeOfDay.fromDateTime(departureTime.value),
                      );
                      if (time == null) return;
                      departureTime.value = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    },
                  )),
              const SizedBox(height: 16),

              // Route (optional)
              TextField(
                controller: routeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Route (optional)',
                  hintText: 'e.g., Central Area → Mosque',
                  prefixIcon: Icon(Icons.route),
                ),
              ),
              const SizedBox(height: 16),

              // Driver info
              TextField(
                controller: driverNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Driver Name (optional)',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: driverMobileCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Driver Mobile (optional)',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) {
                      Get.snackbar('Error', 'Vehicle name is required',
                          snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    final success = await _ctrl.createVehicle(
                      name: nameCtrl.text.trim(),
                      type: selectedType.value,
                      totalSeats: totalSeats.value,
                      departureTime: departureTime.value,
                      route: routeCtrl.text.trim().isEmpty
                          ? null
                          : routeCtrl.text.trim(),
                      driverName: driverNameCtrl.text.trim().isEmpty
                          ? null
                          : driverNameCtrl.text.trim(),
                      driverMobile: driverMobileCtrl.text.trim().isEmpty
                          ? null
                          : driverMobileCtrl.text.trim(),
                    );
                    if (success) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusButton),
                    ),
                  ),
                  child: const Text('Create Vehicle',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Report Bottom Sheet ──────────────────────────────────────────────
  void _showReportSheet(BuildContext context) async {
    await _ctrl.loadReport();
    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Obx(() {
        final r = _ctrl.report.value;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTokens.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Booking Report',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _reportRow(
                  'Total Vehicles', '${r['totalVehicles'] ?? 0}', isDark),
              _reportRow('Total Seats', '${r['totalSeats'] ?? 0}', isDark),
              _reportRow('Booked Seats', '${r['bookedSeats'] ?? 0}', isDark),
              _reportRow(
                  'Available Seats', '${r['availableSeats'] ?? 0}', isDark),
              const Divider(height: 24),
              _reportRow('RSVPs Needing Transport',
                  '${r['confirmedRsvps'] ?? 0}', isDark),
              _reportRow(
                  'Booked Members', '${r['bookedMembers'] ?? 0}', isDark),
              _reportRow('Yet to Book', '${r['unbookedMembers'] ?? 0}', isDark),
              _reportRow(
                  'Occupancy Rate', '${r['occupancyRate'] ?? '0'}%', isDark),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _reportRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: isDark
                      ? AppTokens.darkTextSecondary
                      : AppTokens.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppTokens.darkTextPrimary
                      : AppTokens.textPrimary)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADMIN VEHICLE CARD
// ═══════════════════════════════════════════════════════════════════════════════
class _AdminVehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final List<NewSeatBookingModel> bookings;
  final BookingController ctrl;
  final bool isDark;

  const _AdminVehicleCard({
    required this.vehicle,
    required this.bookings,
    required this.ctrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final rate = vehicle.occupancyRate / 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTokens.darkCard : AppTokens.surfaceCard,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border:
            Border.all(color: isDark ? AppTokens.darkBorder : AppTokens.border),
        boxShadow: isDark ? null : AppTokens.shadowXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTokens.primarySubtle,
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  ),
                  child: const Icon(Icons.directions_bus_rounded,
                      color: AppTokens.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vehicle.name,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppTokens.darkTextPrimary
                                  : AppTokens.textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        '${vehicle.type} · ${vehicle.bookedSeats}/${vehicle.totalSeats} booked',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppTokens.darkTextSecondary
                                : AppTokens.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(vehicle.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  ),
                  child: Text(
                    vehicle.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(vehicle.status),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Progress bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: rate.clamp(0.0, 1.0),
                backgroundColor:
                    isDark ? AppTokens.darkBorder : AppTokens.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  vehicle.hasSeats ? AppTokens.primary : AppTokens.danger,
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Info rows ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                if (vehicle.driverName != null &&
                    vehicle.driverName!.isNotEmpty)
                  _infoRow(Icons.person, 'Driver: ${vehicle.driverName}'),
                if (vehicle.route != null && vehicle.route!.isNotEmpty)
                  _infoRow(Icons.route, vehicle.route!),
                _infoRow(Icons.access_time,
                    'Departs: ${DateFormat('hh:mm a').format(vehicle.departureTime)}'),
              ],
            ),
          ),

          // ── Passengers ─────────────────────────────────────────────
          if (bookings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Passengers (${bookings.length})',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTokens.darkTextSecondary
                          : AppTokens.textSecondary)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: bookings.length,
                itemBuilder: (_, i) {
                  final b = bookings[i];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Tooltip(
                      message: b.userName,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTokens.primary,
                        backgroundImage:
                            b.userAvatar != null && b.userAvatar!.isNotEmpty
                                ? NetworkImage(b.userAvatar!)
                                : null,
                        child: b.userAvatar == null || b.userAvatar!.isEmpty
                            ? Text(
                                b.userName.isNotEmpty
                                    ? b.userName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14))
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),

          // ── Actions row ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: vehicle.bookedSeats > 0
                      ? null
                      : () => _confirmDelete(context),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTokens.danger,
                    disabledForegroundColor: AppTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppTokens.success;
      case 'full':
        return AppTokens.warning;
      case 'inactive':
        return AppTokens.textMuted;
      default:
        return AppTokens.textSecondary;
    }
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 14,
              color:
                  isDark ? AppTokens.darkTextMuted : AppTokens.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTokens.darkTextSecondary
                        : AppTokens.textSecondary)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vehicle?'),
        content: Text('Remove "${vehicle.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.danger,
                foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await ctrl.deleteVehicle(vehicle.id);
  }
}
