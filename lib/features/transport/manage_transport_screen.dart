// lib/features/transport/manage_transport_screen.dart
// UPDATED: added Vehicle Type dropdown (Cruiser / Eeco).
// All existing fields and logic unchanged.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/team_model.dart';
import '../../core/models/seat_booking_model.dart'; // ← NEW
import 'transport_controller.dart';

class ManageTransportScreen extends StatefulWidget {
  const ManageTransportScreen({super.key});

  @override
  State<ManageTransportScreen> createState() => _ManageTransportScreenState();
}

class _ManageTransportScreenState extends State<ManageTransportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _routeCtrl = TextEditingController();
  String? _selectedTeamId;
  List<TeamModel> _teams = [];

  // ── NEW ──────────────────────────────────
  VehicleType _vehicleType = VehicleType.cruiser;

  // 🆕 Event selection
  String? _selectedEventId;
  String? _selectedEventTitle;
  List<Map<String, dynamic>> _availableEvents = [];
  bool _isLoadingEvents = false;

  // 🆕 Enhanced transport management
  final _departureTimeCtrl = TextEditingController();
  final _returnTimeCtrl = TextEditingController();
  final _pickupPointCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  String _priority = 'medium';

  @override
  void initState() {
    super.initState();
    _loadTeams();
    _loadEvents();
  }

  void _loadTeams() {
    final auth = Get.find<AuthController>();
    if (auth.isLeader) {
      FirestoreService.streamAllTeams().first.then((t) {
        if (mounted) setState(() => _teams = t);
      });
    } else {
      setState(() => _selectedTeamId = auth.teamId);
    }
  }

  // 🆕 Load available events
  Future<void> _loadEvents() async {
    setState(() => _isLoadingEvents = true);
    try {
      final ctrl = Get.put(TransportController());
      final events = await ctrl.getAvailableEvents();
      if (mounted) {
        setState(() {
          _availableEvents = events;
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingEvents = false);
      print('Error loading events: $e');
    }
  }

  @override
  void dispose() {
    _vehicleCtrl.dispose();
    _driverCtrl.dispose();
    _routeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(TransportController());
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronLeft,
              color: Colors.white, size: 16),
          onPressed: () => Get.back(),
        ),
        title: const Text('Add Transport'),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // 🆕 Event Selection Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Event Selection',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),

                          // Event dropdown
                          _isLoadingEvents
                              ? const Center(child: CircularProgressIndicator())
                              : DropdownButtonFormField<String>(
                                  initialValue: _selectedEventId,
                                  decoration: const InputDecoration(
                                    labelText: 'Select Event *',
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: FaIcon(
                                          FontAwesomeIcons.calendarDays,
                                          size: 16),
                                    ),
                                  ),
                                  items: _availableEvents
                                      .map<DropdownMenuItem<String>>((event) {
                                    return DropdownMenuItem<String>(
                                      value: event['id']?.toString(),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(event['title'] ?? '',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500)),
                                          Text(
                                              '${event['date']} • ${event['location']}',
                                              style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    final selectedEvent = _availableEvents
                                        .firstWhere((e) => e['id'] == value);
                                    setState(() {
                                      _selectedEventId = value;
                                      _selectedEventTitle =
                                          selectedEvent['title'];
                                    });
                                  },
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Please select an event'
                                      : null,
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vehicle Details',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),

                          // Team selector (leader only) — unchanged
                          if (auth.isLeader && _teams.isNotEmpty)
                            DropdownButtonFormField<String>(
                              initialValue: _selectedTeamId,
                              decoration: const InputDecoration(
                                labelText: 'Assign to Team',
                                prefixIcon: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: FaIcon(FontAwesomeIcons.peopleGroup,
                                      size: 16),
                                ),
                              ),
                              items: _teams
                                  .map((t) => DropdownMenuItem(
                                        value: t.teamId,
                                        child: Text(t.teamName),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedTeamId = v),
                              validator: (v) =>
                                  v == null ? 'Select a team' : null,
                            ),
                          if (auth.isLeader && _teams.isNotEmpty)
                            const SizedBox(height: 16),

                          // ── NEW: Vehicle Type ────────────────
                          DropdownButtonFormField<VehicleType>(
                            initialValue: _vehicleType,
                            decoration: const InputDecoration(
                              labelText: 'Vehicle Type',
                              prefixIcon: Padding(
                                padding: EdgeInsets.all(12),
                                child: FaIcon(FontAwesomeIcons.car, size: 16),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: VehicleType.cruiser,
                                child: Text('Land Cruiser (11 seats)'),
                              ),
                              DropdownMenuItem(
                                value: VehicleType.eeco,
                                child: Text('Maruti Eeco (6 seats)'),
                              ),
                            ],
                            onChanged: (v) => setState(() => _vehicleType = v!),
                          ),
                          const SizedBox(height: 16),
                          // ────────────────────────────────────

                          // Vehicle label — unchanged
                          TextFormField(
                            controller: _vehicleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Vehicle Label / Number',
                              prefixIcon: Padding(
                                padding: EdgeInsets.all(12),
                                child: FaIcon(FontAwesomeIcons.bus, size: 16),
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),

                          // Driver name — unchanged
                          TextFormField(
                            controller: _driverCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Driver Name',
                              prefixIcon: Padding(
                                padding: EdgeInsets.all(12),
                                child:
                                    FaIcon(FontAwesomeIcons.userTie, size: 16),
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),

                          // Route — unchanged
                          TextFormField(
                            controller: _routeCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Route / Description',
                              prefixIcon: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 16),
                                child: FaIcon(FontAwesomeIcons.route, size: 16),
                              ),
                              alignLabelWithHint: true,
                            ),
                          ),

                          // 🆕 Enhanced Transport Management Fields
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),

                          Text('Transport Schedule',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _departureTimeCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Departure Time',
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: FaIcon(FontAwesomeIcons.clock,
                                          size: 16),
                                    ),
                                    hintText: 'YYYY-MM-DD HH:MM',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _returnTimeCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Return Time',
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: FaIcon(FontAwesomeIcons.clock,
                                          size: 16),
                                    ),
                                    hintText: 'YYYY-MM-DD HH:MM',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _pickupPointCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Pickup Point',
                              prefixIcon: Padding(
                                padding: EdgeInsets.all(12),
                                child: FaIcon(FontAwesomeIcons.locationDot,
                                    size: 16),
                              ),
                              hintText: 'e.g., Main Masjid, Dohad',
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _contactPersonCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Contact Person',
                              prefixIcon: Padding(
                                padding: EdgeInsets.all(12),
                                child: FaIcon(FontAwesomeIcons.phone, size: 16),
                              ),
                              hintText: 'Name and phone number',
                            ),
                          ),
                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            initialValue: _priority,
                            decoration: const InputDecoration(
                              labelText: 'Priority Level',
                              prefixIcon: Padding(
                                padding: EdgeInsets.all(12),
                                child: FaIcon(FontAwesomeIcons.flag, size: 16),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'high', child: Text('High')),
                              DropdownMenuItem(
                                  value: 'medium', child: Text('Medium')),
                              DropdownMenuItem(
                                  value: 'low', child: Text('Low')),
                            ],
                            onChanged: (value) =>
                                setState(() => _priority = value!),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: ctrl.isLoading.value
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    ctrl.createTransport(
                                      // 🆕 Required event linkage
                                      eventId: _selectedEventId ?? '',
                                      eventTitle: _selectedEventTitle ?? '',

                                      // Existing
                                      teamId: _selectedTeamId ?? auth.teamId,
                                      vehicleLabel: _vehicleCtrl.text.trim(),
                                      driverName: _driverCtrl.text.trim(),
                                      route: _routeCtrl.text.trim(),
                                      vehicleType: _vehicleType,

                                      // 🆕 Enhanced transport management
                                      departureTime:
                                          _departureTimeCtrl.text.isNotEmpty
                                              ? DateTime.tryParse(
                                                  _departureTimeCtrl.text)
                                              : null,
                                      returnTime:
                                          _returnTimeCtrl.text.isNotEmpty
                                              ? DateTime.tryParse(
                                                  _returnTimeCtrl.text)
                                              : null,
                                      pickupPoint:
                                          _pickupPointCtrl.text.trim().isEmpty
                                              ? null
                                              : _pickupPointCtrl.text.trim(),
                                      contactPerson:
                                          _contactPersonCtrl.text.trim().isEmpty
                                              ? null
                                              : _contactPersonCtrl.text.trim(),
                                      priority: _priority,
                                    );
                                  }
                                },
                          icon: ctrl.isLoading.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const FaIcon(FontAwesomeIcons.floppyDisk,
                                  size: 14),
                          label: const Text('Save Transport'),
                        ),
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
