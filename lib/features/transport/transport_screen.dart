// lib/features/transport/transport_screen.dart
// UNIFIED: Transport + Seat Booking + My Bookings — all in one tabbed screen.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/models/transport_model.dart';
import '../../core/models/seat_booking_model.dart';
import '../../core/widgets/shimmer_widgets.dart';
import 'transport_controller.dart';
import 'manage_transport_screen.dart';
import 'seat_map_screen.dart';

class TransportScreen extends StatefulWidget {
  const TransportScreen({super.key});

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      body: Column(
        children: [
          // ── Tab Bar ───────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              border: Border(
                bottom:
                    BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: const Color(0xFF059669),
              indicatorWeight: 3,
              labelColor: const Color(0xFF059669),
              unselectedLabelColor: Colors.white54,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(
                  icon: FaIcon(FontAwesomeIcons.bus, size: 16),
                  text: 'Vehicles',
                ),
                Tab(
                  icon: FaIcon(FontAwesomeIcons.ticket, size: 16),
                  text: 'My Bookings',
                ),
              ],
            ),
          ),
          // ── Tab Content ──────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _VehiclesTab(),
                _MyBookingsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        if (_tabCtrl.index == 0 && auth.isSupervisorOrLeader) {
          return FloatingActionButton.extended(
            onPressed: () => Get.to(() => const ManageTransportScreen()),
            backgroundColor: const Color(0xFF059669),
            icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
            label: const Text('Add Vehicle'),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1: VEHICLES LIST
// ═══════════════════════════════════════════════════════════════════════════════
class _VehiclesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(TransportController());
    final auth = Get.find<AuthController>();

    return RefreshIndicator(
      onRefresh: () async {},
      color: const Color(0xFF059669),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return Obx(() {
            if (!ctrl.hasLoaded.value) {
              return const CardListShimmer(itemCount: 3, cardHeight: 90);
            }
            if (ctrl.transports.isEmpty) {
              return ListView(
                padding: EdgeInsets.all(padding),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF059669).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: FaIcon(FontAwesomeIcons.bus,
                                size: 32, color: Color(0xFF059669)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('No vehicles available',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                            auth.isSupervisorOrLeader
                                ? 'Tap + to add a vehicle for your team.'
                                : 'No transport arranged yet. Check back later.',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ],
              );
            }
            return ListView(
              padding: EdgeInsets.all(padding),
              children: [
                ...ctrl.transports.map((t) =>
                    _TransportCard(transport: t, ctrl: ctrl, auth: auth)),
              ],
            );
          });
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2: MY BOOKINGS (live from Firestore transport/{id}/bookings)
// ═══════════════════════════════════════════════════════════════════════════════
class _MyBookingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final uid = auth.uid;

    if (uid.isEmpty) {
      return const Center(
          child: Text('Please log in to see bookings',
              style: TextStyle(color: Colors.white54)));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transport').snapshots(),
      builder: (context, transportSnap) {
        if (transportSnap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)));
        }
        if (!transportSnap.hasData || transportSnap.data!.docs.isEmpty) {
          return _emptyBookings();
        }

        // For each transport, check if user has a booking
        final transportDocs = transportSnap.data!.docs;
        return _MyBookingsLiveList(transportDocs: transportDocs, uid: uid);
      },
    );
  }

  Widget _emptyBookings() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF059669).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Center(
              child: FaIcon(FontAwesomeIcons.ticket,
                  size: 32, color: Color(0xFF059669)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('No bookings yet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Book a seat from the Vehicles tab',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MyBookingsLiveList extends StatelessWidget {
  final List<QueryDocumentSnapshot> transportDocs;
  final String uid;

  const _MyBookingsLiveList(
      {required this.transportDocs, required this.uid});

  @override
  Widget build(BuildContext context) {
    // Build a list of FutureBuilders that check each transport's bookings
    return FutureBuilder<List<_MyBookingInfo>>(
      future: _fetchMyBookings(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)));
        }
        final bookings = snap.data ?? [];
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF059669).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: FaIcon(FontAwesomeIcons.ticket,
                        size: 32, color: Color(0xFF059669)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('No bookings yet',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Book a seat from the Vehicles tab',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (_, i) => _MyBookingCard(info: bookings[i]),
        );
      },
    );
  }

  Future<List<_MyBookingInfo>> _fetchMyBookings() async {
    final results = <_MyBookingInfo>[];
    for (final tDoc in transportDocs) {
      final data = tDoc.data() as Map<String, dynamic>;
      final bookingsSnap = await FirebaseFirestore.instance
          .collection('transport')
          .doc(tDoc.id)
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .get();
      for (final bDoc in bookingsSnap.docs) {
        final bData = bDoc.data();
        results.add(_MyBookingInfo(
          transportId: tDoc.id,
          seatId: bDoc.id,
          vehicleLabel: data['vehicleLabel'] ?? 'Unknown Vehicle',
          vehicleType: data['vehicleType'] ?? 'cruiser',
          driverName: data['driverName'] ?? '',
          route: data['route'] ?? '',
          departureTime: data['departureTime'] is Timestamp
              ? (data['departureTime'] as Timestamp).toDate()
              : null,
          eventTitle: data['eventTitle'] ?? '',
          bookedAt: bData['bookedAt'] is Timestamp
              ? (bData['bookedAt'] as Timestamp).toDate()
              : DateTime.now(),
          status: data['status'] ?? 'active',
        ));
      }
    }
    results.sort((a, b) => b.bookedAt.compareTo(a.bookedAt));
    return results;
  }
}

class _MyBookingInfo {
  final String transportId;
  final String seatId;
  final String vehicleLabel;
  final String vehicleType;
  final String driverName;
  final String route;
  final DateTime? departureTime;
  final String eventTitle;
  final DateTime bookedAt;
  final String status;

  _MyBookingInfo({
    required this.transportId,
    required this.seatId,
    required this.vehicleLabel,
    required this.vehicleType,
    required this.driverName,
    required this.route,
    this.departureTime,
    required this.eventTitle,
    required this.bookedAt,
    required this.status,
  });
}

class _MyBookingCard extends StatelessWidget {
  final _MyBookingInfo info;
  const _MyBookingCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final isActive = info.status == 'active';
    final typeLabel =
        info.vehicleType == 'eeco' ? 'Eeco' : 'Land Cruiser';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF059669).withOpacity(0.08),
            const Color(0xFF00897B).withOpacity(0.04),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF059669).withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // Top bar with seat badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                // Seat badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00897B).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF26C6DA).withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(FontAwesomeIcons.chair,
                          size: 12, color: Color(0xFF26C6DA)),
                      const SizedBox(width: 6),
                      Text(
                        'Seat ${info.seatId}',
                        style: const TextStyle(
                          color: Color(0xFF26C6DA),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isActive
                            ? const Color(0xFF4CAF50)
                            : Colors.orange)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (isActive
                              ? const Color(0xFF4CAF50)
                              : Colors.orange)
                          .withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    isActive ? 'CONFIRMED' : 'INACTIVE',
                    style: TextStyle(
                      color:
                          isActive ? const Color(0xFF4CAF50) : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Vehicle info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const FaIcon(FontAwesomeIcons.bus,
                          size: 18, color: Color(0xFF059669)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info.vehicleLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: const TextStyle(
                                    color: Color(0xFF059669),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (info.driverName.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                FaIcon(FontAwesomeIcons.userTie,
                                    size: 10,
                                    color: Colors.white.withOpacity(0.4)),
                                const SizedBox(width: 4),
                                Text(info.driverName,
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 11)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Info rows
                if (info.eventTitle.isNotEmpty)
                  _infoRow(FontAwesomeIcons.calendarDays,
                      'Event: ${info.eventTitle}'),
                if (info.route.isNotEmpty)
                  _infoRow(FontAwesomeIcons.route, info.route),
                if (info.departureTime != null)
                  _infoRow(FontAwesomeIcons.clock,
                      'Departure: ${DateFormat('dd MMM, hh:mm a').format(info.departureTime!)}'),
                _infoRow(FontAwesomeIcons.calendarCheck,
                    'Booked: ${DateFormat('dd MMM yyyy, hh:mm a').format(info.bookedAt)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          FaIcon(icon, size: 12, color: Colors.white38),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TRANSPORT VEHICLE CARD
// ═══════════════════════════════════════════════════════════════════════════════
class _TransportCard extends StatelessWidget {
  final TransportModel transport;
  final TransportController ctrl;
  final AuthController auth;

  const _TransportCard(
      {required this.transport, required this.ctrl, required this.auth});

  @override
  Widget build(BuildContext context) {
    final isActive = transport.status == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: isActive
              ? const Color(0xFF059669).withOpacity(0.3)
              : Colors.white.withOpacity(0.08),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF059669).withOpacity(0.15)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF059669).withOpacity(0.3)
                          : Colors.white12,
                    ),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.bus,
                    color:
                        isActive ? const Color(0xFF059669) : Colors.white30,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transport.vehicleLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.userTie,
                              size: 10, color: Colors.white38),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(transport.driverName,
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF059669).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: const Color(0xFF059669)
                                      .withOpacity(0.3)),
                            ),
                            child: Text(
                              transport.vehicleType.label,
                              style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF4CAF50).withOpacity(0.15)
                        : Colors.white.withOpacity(0.06),
                    border: Border.all(
                        color: isActive
                            ? const Color(0xFF4CAF50).withOpacity(0.4)
                            : Colors.white.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFF81C784)
                          : Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Event + departure info ────────────────────────
          if (transport.eventId.isNotEmpty && transport.eventTitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.calendarDays,
                      color: Color(0xFF047857), size: 13),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${transport.eventTitle}',
                      style: const TextStyle(
                        color: Color(0xFF047857),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (transport.departureTime != null)
                    Text(
                      '${transport.departureTime!.hour.toString().padLeft(2, '0')}:${transport.departureTime!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: const Color(0xFF047857).withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

          if (transport.route.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.route,
                      size: 11, color: Colors.white30),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(transport.route,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
                height: 1, color: Colors.white.withOpacity(0.06)),
          ),
          const SizedBox(height: 10),

          // ── Action row ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                if (isActive)
                  Expanded(child: _BookSeatsButton(transport: transport)),
                if (isActive && auth.isSupervisorOrLeader)
                  const SizedBox(width: 8),
                if (auth.isSupervisorOrLeader) ...[
                  if (isActive)
                    _ActionChip(
                      icon: FontAwesomeIcons.pause,
                      label: 'Stop',
                      color: Colors.orange,
                      onTap: () => ctrl.updateStatus(
                          transport.id, 'inactive'),
                    )
                  else
                    _ActionChip(
                      icon: FontAwesomeIcons.play,
                      label: 'Activate',
                      color: const Color(0xFF059669),
                      onTap: () =>
                          ctrl.updateStatus(transport.id, 'active'),
                    ),
                  const SizedBox(width: 6),
                  _ActionChip(
                    icon: FontAwesomeIcons.trash,
                    label: 'Delete',
                    color: Colors.red,
                    onTap: () => _confirmDelete(context),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text(
            'Remove "${transport.vehicleLabel}" from transport records?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctrl.deleteTransport(transport.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Small action chip for admin buttons
// ─────────────────────────────────────────────────────────
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 11, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Book Seats button — live seat count from Firestore
// ─────────────────────────────────────────────────────────
class _BookSeatsButton extends StatelessWidget {
  final TransportModel transport;
  const _BookSeatsButton({required this.transport});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: FirebaseFirestore.instance
          .collection('transport')
          .doc(transport.id)
          .collection('bookings')
          .snapshots()
          .map((snap) => snap.docs.length),
      builder: (_, snap) {
        final booked = snap.data ?? 0;
        final total = transport.totalSeats;
        final available = total - booked;
        final isFull = available <= 0;

        return ElevatedButton.icon(
          onPressed: isFull
              ? null
              : () => Get.to(
                    () => SeatMapScreen(transport: transport),
                    transition: Transition.rightToLeft,
                  ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isFull ? Colors.white12 : const Color(0xFF00897B),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          icon: FaIcon(
            isFull ? FontAwesomeIcons.ban : FontAwesomeIcons.chair,
            size: 13,
            color: isFull ? Colors.white30 : Colors.white,
          ),
          label: Text(
            isFull ? 'Full' : 'Book Seat ($available left)',
            style: TextStyle(
              color: isFull ? Colors.white30 : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
