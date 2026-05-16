import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/models/event_model.dart';
import '../../core/models/team_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/shimmer_widgets.dart';
import 'events_controller.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(EventsController());
    final auth = Get.find<AuthController>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: ctrl.refresh,
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
            return Obx(() {
              if (!ctrl.hasLoaded.value) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: padding / 2),
                  child: Column(
                    children: List.generate(3, (_) => const EventCardShimmer()),
                  ),
                );
              }
              if (ctrl.events.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.calendarXmark,
                          size: 48, color: Colors.white30),
                      SizedBox(height: 12),
                      Text('No events yet',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 16)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.all(padding),
                itemCount: ctrl.events.length,
                itemBuilder: (ctx, i) {
                  final event = ctrl.events[i];
                  return _EventCard(
                    event: event,
                    rsvpStatus: ctrl.rsvpStatusFor(event.eventId),
                  );
                },
              );
            });
          },
        ),
      ),
      floatingActionButton: auth.isSupervisorOrLeader
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(context, ctrl),
              icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
              label: const Text('New Event'),
            )
          : null,
    );
  }

  void _showCreateDialog(BuildContext context, EventsController ctrl) {
    final titleCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    bool rsvpEnabled = true;
    bool attEnabled = true;
    final formKey = GlobalKey<FormState>();

    String targetType = 'all'; // all | team | role
    TeamModel? selectedTeam;
    String? selectedRole;
    final RxList<TeamModel> teams = <TeamModel>[].obs;
    FirestoreService.streamAllTeams().listen((t) => teams.value = t);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create Event'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Event Title'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(labelText: 'Location'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      dense: true,
                      leading:
                          const FaIcon(FontAwesomeIcons.calendar, size: 16),
                      title:
                          Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                      trailing:
                          const FaIcon(FontAwesomeIcons.chevronRight, size: 12),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                    SwitchListTile(
                      dense: true,
                      title: const Text('RSVP Enabled'),
                      value: rsvpEnabled,
                      onChanged: (v) => setState(() => rsvpEnabled = v),
                    ),
                    SwitchListTile(
                      dense: true,
                      title: const Text('Attendance Tracking'),
                      value: attEnabled,
                      onChanged: (v) => setState(() => attEnabled = v),
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 6),
                      child: Text('Target Audience',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: targetType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(12),
                          child: FaIcon(FontAwesomeIcons.bullseye, size: 14),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All Members')),
                        DropdownMenuItem(
                            value: 'team', child: Text('Specific Team')),
                        DropdownMenuItem(value: 'role', child: Text('By Role')),
                      ],
                      onChanged: (v) => setState(() => targetType = v ?? 'all'),
                    ),
                    if (targetType == 'team') ...[
                      const SizedBox(height: 8),
                      Obx(() {
                        if (teams.isEmpty) {
                          return const ShimmerBox(
                              width: double.infinity,
                              height: 56,
                              borderRadius: 8);
                        }
                        return DropdownButtonFormField<TeamModel>(
                          initialValue: selectedTeam,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Team',
                          ),
                          items: teams
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t.teamName,
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => selectedTeam = v),
                        );
                      }),
                    ],
                    if (targetType == 'role') ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: const [
                          DropdownMenuItem(
                              value: 'member', child: Text('Members')),
                          DropdownMenuItem(
                              value: 'supervisor', child: Text('Supervisors')),
                          DropdownMenuItem(
                              value: 'leader', child: Text('Leaders')),
                        ],
                        onChanged: (v) => setState(() => selectedRole = v),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            Obx(() => ElevatedButton.icon(
                  onPressed: ctrl.isLoading.value
                      ? null
                      : () {
                          if (!formKey.currentState!.validate()) return;
                          if (targetType == 'team' && selectedTeam == null) {
                            Get.snackbar('Pick a team',
                                'Please choose a team to target.',
                                snackPosition: SnackPosition.BOTTOM);
                            return;
                          }
                          if (targetType == 'role' && selectedRole == null) {
                            Get.snackbar('Pick a role', 'Please choose a role.',
                                snackPosition: SnackPosition.BOTTOM);
                            return;
                          }
                          ctrl.createEvent(
                            title: titleCtrl.text.trim(),
                            eventDate: selectedDate,
                            location: locationCtrl.text.trim(),
                            rsvpEnabled: rsvpEnabled,
                            attendanceEnabled: attEnabled,
                            targetType: targetType,
                            targetTeamId: selectedTeam?.teamId,
                            targetRole: selectedRole,
                          );
                          Navigator.pop(ctx);
                        },
                  icon: ctrl.isLoading.value
                      ? const ButtonLoader()
                      : const FaIcon(FontAwesomeIcons.check, size: 14),
                  label: const Text('Create'),
                )),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final String? rsvpStatus;

  const _EventCard({required this.event, this.rsvpStatus});

  @override
  Widget build(BuildContext context) {
    final isPast = event.eventDate.isBefore(DateTime.now());
    final accentColor =
        isPast ? const Color(0xFF607D8B) : const Color(0xFF059669);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6), // Reduced from 10 to 6
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12), // Reduced from 14 to 12
          onTap: () => Get.to(() => EventDetailScreen(event: event)),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12), // Reduced from 14 to 12
              gradient: isPast
                  ? LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.02),
                        Colors.white.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        accentColor.withOpacity(0.08),
                        accentColor.withOpacity(0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              border: Border.all(
                color: accentColor.withOpacity(isPast ? 0.15 : 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Left accent bar with gradient
                  Container(
                    width: 3, // Reduced from 4 to 3
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPast
                            ? [
                                accentColor.withOpacity(0.3),
                                accentColor.withOpacity(0.1),
                              ]
                            : [
                                accentColor.withOpacity(0.8),
                                accentColor.withOpacity(0.4),
                              ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                  // Date badge - more compact
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10), // Reduced from 14,14 to 10,10
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            DateFormat('dd').format(event.eventDate),
                            style: TextStyle(
                              fontSize: 18, // Reduced from 22 to 18
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM')
                              .format(event.eventDate)
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 8, // Reduced from 10 to 8
                            fontWeight: FontWeight.w600,
                            color: accentColor.withOpacity(0.7),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Subtle divider
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(
                        vertical: 8), // Reduced from 12 to 8
                    color: Colors.white.withOpacity(0.06),
                  ),
                  // Content - more compact
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8), // Reduced from 14,12 to 10,8
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!isPast)
                            Container(
                              margin: const EdgeInsets.only(
                                  bottom: 3), // Reduced from 5 to 3
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1), // Reduced from 7,2 to 5,1
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accentColor.withOpacity(0.2),
                                    accentColor.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'UPCOMING',
                                style: TextStyle(
                                  fontSize: 8, // Reduced from 9 to 8
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          Text(
                            event.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14, // Reduced from 15 to 14
                              color: isPast ? Colors.white60 : Colors.white,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3), // Reduced from 4 to 3
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const FaIcon(FontAwesomeIcons.locationDot,
                                    size: 9, // Reduced from 11 to 9
                                    color: Colors.white70),
                              ),
                              const SizedBox(width: 4), // Reduced from 5 to 4
                              Expanded(
                                child: Text(
                                  event.location,
                                  style: const TextStyle(
                                      color: Colors
                                          .white60, // Changed from white54 to white60
                                      fontSize: 11), // Reduced from 12 to 11
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Right: RSVP badge + chevron - more compact
                  Padding(
                    padding:
                        const EdgeInsets.only(right: 8), // Reduced from 12 to 8
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (rsvpStatus != null) ...[
                          _RsvpBadge(status: rsvpStatus!),
                          const SizedBox(height: 4) // Reduced from 6 to 4
                        ],
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FaIcon(FontAwesomeIcons.chevronRight,
                              size: 10, // Reduced from 12 to 10
                              color: accentColor.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RsvpBadge extends StatelessWidget {
  final String status;
  const _RsvpBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'attending':
        color = Colors.green;
        label = 'Going';
        break;
      case 'not_attending':
        color = Colors.red;
        label = 'Not Going';
        break;
      default:
        color = Colors.orange;
        label = 'Pending';
    }
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
