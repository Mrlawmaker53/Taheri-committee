import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/event_model.dart';

class EventRepository {
  final _db = FirebaseFirestore.instance;

  Stream<List<EventModel>> watchEvents() {
    return _db
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(EventModel.fromFirestore).toList());
  }

  Future<void> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String departureTime,
    required String departureLocation,
    required String destination,
    required String vehicleType,
    required String createdBy,
  }) async {
    final totalSeats = vehicleType == 'cruiser' ? 11 : 6;
    
    await _db.collection('events').add({
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'departureTime': departureTime,
      'departureLocation': departureLocation,
      'destination': destination,
      'vehicleType': vehicleType,
      'totalSeats': totalSeats,
      'status': 'open',
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateEventStatus(String eventId, String status) async {
    await _db.doc('events/$eventId').update({'status': status});
  }
}
