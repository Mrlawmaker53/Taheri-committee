import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_tokens.dart';
import '../domain/event_model.dart';
import '../data/event_repository.dart';
import 'seat_map_screen.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  final EventRepository _eventRepo = EventRepository();
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seat Booking Events'),
        backgroundColor: AppTokens.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_auth.currentUser != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createSampleEvent,
              tooltip: 'Create Sample Event',
            ),
        ],
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: _eventRepo.watchEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text('Error loading events',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(),
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createSampleEvent,
                    child: const Text('Create Sample Event'),
                  ),
                ],
              ),
            );
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_seat, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No events found',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Create your first seat booking event',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createSampleEvent,
                    child: const Text('Create Sample Event'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTokens.accent.withOpacity(0.2),
                    child: Icon(
                      event.vehicleType == 'cruiser'
                          ? Icons.directions_car
                          : Icons.directions_bus,
                      color: AppTokens.accent,
                    ),
                  ),
                  title: Text(event.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${event.date.day}/${event.date.month}/${event.date.year} at ${event.departureTime}'),
                      Text('${event.departureLocation} → ${event.destination}'),
                      Text(
                          '${event.vehicleType.toUpperCase()} • ${event.totalSeats} seats'),
                    ],
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: event.status == 'open'
                          ? AppTokens.success.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.status.toUpperCase(),
                      style: TextStyle(
                        color: event.status == 'open'
                            ? AppTokens.success
                            : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  onTap: () {
                    Get.to(() => SeatMapScreen(event: event));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _createSampleEvent() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Get.snackbar('Error', 'Please login first');
        return;
      }

      await _eventRepo.createEvent(
        title: 'Sample Event - ${DateTime.now().day}/${DateTime.now().month}',
        description:
            'This is a sample event for testing the seat booking system',
        date: DateTime.now().add(const Duration(days: 2)),
        departureTime: '6:30 PM',
        departureLocation: 'Central Mosque',
        destination: 'Community Hall',
        vehicleType: 'cruiser',
        createdBy: user.uid,
      );

      Get.snackbar('Success', 'Sample event created successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to create event: $e');
    }
  }
}
