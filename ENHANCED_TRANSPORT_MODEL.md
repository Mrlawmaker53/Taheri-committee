# Enhanced Event-Based Transport System

## 📋 **Complete Firebase Structure**

### 1. Events Collection (Existing - Enhance)
```javascript
/events/{eventId} {
  title: "Sunday Ziyarat - Mazar-e-Fakhri",
  createdBy: "leader_uid", 
  eventDate: Timestamp("2026-05-10T08:00:00Z"),
  location: "Galiyat, Dohad",
  rsvpEnabled: true,
  attendanceEnabled: true,
  
  // 🆕 TRANSPORT FIELDS
  transportRequired: true,
  transportCapacity: 50,        // Expected attendees
  transportStatus: "planning",   // planning | active | completed
  transportNotes: "Departing from Masjid at 6:00 AM"
}
```

### 2. Transport Collection (Enhanced)
```javascript
/transport/{transportId} {
  // 🆕 EVENT LINKAGE
  eventId: "event_abc",          // Links to specific event
  teamId: "team_abc",
  
  // Existing fields
  vehicleLabel: "TC Bus 1 - Sunday Ziyarat",
  driverName: "Ahmed",
  vehicleType: "cruiser",
  route: "Masjid Dohad → Galiyat",
  status: "active",
  
  // 🆕 TRANSPORT MANAGEMENT
  departureTime: Timestamp("2026-05-10T06:00:00Z"),
  returnTime: Timestamp("2026-05-10T18:00:00Z"),
  pickupPoint: "Main Masjid, Dohad",
  contactPerson: "Ahmed - +91 98765 43210",
  priority: "high",              // high | medium | low
  
  // 🆕 CAPACITY TRACKING
  totalCapacity: 11,             // From vehicleType
  currentBookings: 7,           // Real-time count
  waitingList: 3,               // Users waiting for seats
  
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### 3. Bookings Subcollection (Enhanced)
```javascript
/transport/{transportId}/bookings/{seatId} {
  // Existing fields
  userId: "user_uid",
  displayName: "Riya M.",
  avatarUrl: "https://...",
  bookedAt: Timestamp,
  
  // 🆕 BOOKING METADATA
  eventId: "event_abc",          // Event context
  teamId: "team_abc",
  bookingStatus: "confirmed",    // confirmed | cancelled | waiting
  priority: "member",            // member | volunteer | elder | priority
  
  // 🆕 CONTACT & LOGISTICS
  contactNumber: "+91 98765 43210",
  emergencyContact: "+91 98765 43211",
  specialRequirements: "Wheelchair access needed",
  pickupConfirmation: true
}
```

### 4. 🆕 Waiting List Subcollection
```javascript
/transport/{transportId}/waitingList/{userId} {
  userId: "user_uid",
  displayName: "Mohammed S.",
  eventId: "event_abc",
  requestedAt: Timestamp,
  priority: "member",
  contactNumber: "+91 98765 43210",
  status: "waiting"              // waiting | notified | seated | cancelled
}
```

## 🎯 **Admin Workflow**

### Step 1: Create Event First
```dart
// Admin creates event with transport details
EventModel event = EventModel(
  title: "Sunday Ziyarat - Mazar-e-Fakhri",
  eventDate: DateTime(2026, 5, 10, 8, 0),
  location: "Galiyat, Dohad",
  transportRequired: true,
  transportCapacity: 50,
  transportStatus: "planning"
);
```

### Step 2: Create Transport for Event
```dart
// Admin creates vehicles linked to event
TransportModel transport = TransportModel(
  eventId: "event_abc",          // 🆕 Link to event
  teamId: "team_abc",
  vehicleLabel: "TC Bus 1 - Sunday Ziyarat",
  vehicleType: VehicleType.cruiser,
  departureTime: DateTime(2026, 5, 10, 6, 0),
  pickupPoint: "Main Masjid, Dohad"
);
```

### Step 3: Monitor Capacity
```dart
// Real-time capacity tracking
StreamBuilder(
  stream: FirebaseFirestore.instance
    .collection('transport')
    .doc(transportId)
    .snapshots(),
  builder: (_, snap) {
    final bookings = snap.data?['currentBookings'] ?? 0;
    final capacity = snap.data?['totalCapacity'] ?? 0;
    
    return Column(
      children: [
        Text('$bookings/$capacity seats booked'),
        if (bookings >= capacity) 
          Text('FULL - Waiting List Available', 
               style: TextStyle(color: Colors.orange)),
      ],
    );
  },
)
```

## 👥 **User Experience**

### Event Screen with Transport Info
```dart
// events_screen.dart - Show transport availability
Widget _buildTransportCard(EventModel event) {
  return FutureBuilder(
    future: getTransportForEvent(event.eventId),
    builder: (_, snap) {
      if (snap.hasData) {
        final transport = snap.data!;
        return Card(
          child: ListTile(
            leading: FaIcon(FontAwesomeIcons.bus),
            title: Text('Transport Available'),
            subtitle: Text('${transport.currentBookings}/${transport.totalCapacity} seats'),
            trailing: transport.currentBookings < transport.totalCapacity
              ? ElevatedButton(
                  onPressed: () => Get.to(() => SeatMapScreen(transport: transport)),
                  child: Text('Book Seat'))
              : Text('FULL', style: TextStyle(color: Colors.red)),
          ),
        );
      }
      return SizedBox.shrink();
    },
  );
}
```

### Smart Seat Booking
```dart
// seat_booking_controller.dart - Enhanced booking logic
Future<void> confirmBooking() async {
  if (availableCount <= 0) {
    // 🆕 Auto-add to waiting list
    await addToWaitingList(userId, eventId);
    Get.snackbar('Added to Waiting List', 'We\'ll notify you when a seat is available');
    return;
  }
  
  // Existing booking logic...
}
```

## 📊 **Analytics & Reports**

### Transport Utilization
```dart
// Admin dashboard - transport efficiency
class TransportAnalytics {
  Stream<List<Map<String, dynamic>>> getTransportUtilization() {
    return FirebaseFirestore.instance
      .collection('transport')
      .where('eventId', isEqualTo: eventId)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => {
        'vehicleLabel': doc['vehicleLabel'],
        'utilization': (doc['currentBookings'] / doc['totalCapacity']) * 100,
        'status': doc['status'],
        'waitingList': doc['waitingList']
      }).toList());
  }
}
```

## 🚨 **Missing Features to Implement**

### 1. Event-Transport Linkage
- Add `eventId` field to TransportModel
- Update transport creation to require event selection
- Filter transports by event

### 2. Enhanced Transport Management
- Departure/return times
- Pickup points
- Contact information
- Priority booking system

### 3. Waiting List System
- Automatic notifications when seats available
- Priority-based allocation
- SMS/WhatsApp notifications

### 4. Transport Analytics
- Utilization reports
- Peak time analysis
- Vehicle performance tracking

### 5. Enhanced User Experience
- Event-based transport discovery
- Real-time seat availability
- Booking confirmations with QR codes

## 🔥 **Implementation Priority**

1. **HIGH** - Add eventId linkage to transport
2. **HIGH** - Update transport creation workflow  
3. **MEDIUM** - Implement waiting list system
4. **MEDIUM** - Add transport analytics
5. **LOW** - Enhanced notifications and QR codes
