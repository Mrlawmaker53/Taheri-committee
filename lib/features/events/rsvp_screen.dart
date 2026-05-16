import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/models/event_model.dart';
import 'events_controller.dart';

class RsvpScreen extends StatelessWidget {
  const RsvpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final EventModel event = Get.arguments as EventModel? ?? _placeholder();
    final ctrl = Get.find<EventsController>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronLeft,
              color: Colors.white, size: 16),
          onPressed: () => Get.back(),
        ),
        title: const Text('RSVP'),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.calendar,
                                size: 13, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('dd MMM yyyy').format(event.eventDate),
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.locationDot,
                                size: 13, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                event.location,
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Will you attend?',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Obx(() {
                  final status = ctrl.rsvpStatusFor(event.eventId);
                  final needsTransport = ctrl.needsTransportFor(event.eventId);
                  return Column(
                    children: [
                      _RsvpOption(
                        icon: FontAwesomeIcons.circleCheck,
                        label: 'Yes, I\'ll be there',
                        color: Colors.green,
                        isSelected: status == 'attending',
                        onTap: () => ctrl.submitRsvp(event.eventId, 'attending',
                            needsTransport: needsTransport),
                      ),
                      const SizedBox(height: 12),
                      _RsvpOption(
                        icon: FontAwesomeIcons.circleXmark,
                        label: 'No, I can\'t make it',
                        color: Colors.red,
                        isSelected: status == 'not_attending',
                        onTap: () =>
                            ctrl.submitRsvp(event.eventId, 'not_attending'),
                      ),
                      const SizedBox(height: 12),
                      _RsvpOption(
                        icon: FontAwesomeIcons.circleQuestion,
                        label: 'Not sure yet',
                        color: Colors.orange,
                        isSelected: status == 'maybe',
                        onTap: () => ctrl.submitRsvp(event.eventId, 'maybe'),
                      ),
                      // Transport checkbox — only visible when attending
                      if (status == 'attending') ...[
                        const SizedBox(height: 20),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: needsTransport
                                ? const Color(0xFFECFDF5)
                                : Colors.transparent,
                            border: Border.all(
                              color: needsTransport
                                  ? const Color(0xFF059669)
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CheckboxListTile(
                            value: needsTransport,
                            onChanged: (val) {
                              ctrl.submitRsvp(event.eventId, 'attending',
                                  needsTransport: val ?? false);
                            },
                            title: const Text('I need transport',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: const Text(
                                'Check this to book a seat on event vehicles'),
                            secondary: const FaIcon(FontAwesomeIcons.bus,
                                color: Color(0xFF059669), size: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            activeColor: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  EventModel _placeholder() => EventModel(
        eventId: '',
        title: 'Event',
        createdBy: '',
        eventDate: DateTime.now(),
        location: '',
        rsvpEnabled: true,
        attendanceEnabled: true,
      );
}

class _RsvpOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RsvpOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        border: Border.all(
            color: isSelected ? color : Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: FaIcon(icon, color: color, size: 22),
        title: Text(
          label,
          style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : null),
        ),
        trailing: isSelected
            ? FaIcon(FontAwesomeIcons.check, color: color, size: 16)
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
