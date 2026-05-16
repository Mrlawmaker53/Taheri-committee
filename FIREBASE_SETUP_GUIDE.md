# Firebase Collections Setup Guide

## 🚀 **Quick Setup via Firebase Console**

### 1. Go to Firebase Console
- Open: https://console.firebase.google.com
- Select your project
- Go to **Firestore Database**

### 2. Create Events Collection
```javascript
// Collection: events
// Document ID: auto-generated
{
  title: "Sunday Ziyarat - Mazar-e-Fakhri",
  createdBy: "rBFiyTVP1JhUQZ0XfiUABOoS4vB2", // Your admin UID
  eventDate: "2026-05-10T08:00:00Z",
  location: "Galiyat, Dohad", 
  rsvpEnabled: true,
  attendanceEnabled: true,
  transportRequired: true,
  transportCapacity: 50,
  transportStatus: "planning",
  transportNotes: "Departing from Masjid at 6:00 AM",
  createdAt: "2026-05-07T00:00:00Z"
}
```

### 3. Create Transport Collection
```javascript
// Collection: transport  
// Document ID: auto-generated
{
  eventId: "event_abc_id", // Copy from events collection
  teamId: "team_abc",
  vehicleLabel: "TC Bus 1 - Sunday Ziyarat",
  driverName: "Ahmed",
  vehicleType: "cruiser",
  route: "Masjid Dohad → Galiyat",
  status: "active",
  departureTime: "2026-05-10T06:00:00Z",
  returnTime: "2026-05-10T18:00:00Z", 
  pickupPoint: "Main Masjid, Dohad",
  contactPerson: "Ahmed - +91 98765 43210",
  priority: "high",
  totalCapacity: 11,
  currentBookings: 0,
  waitingList: 0,
  createdAt: "2026-05-07T00:00:00Z",
  updatedAt: "2026-05-07T00:00:00Z"
}
```

### 4. Create Bookings Subcollection (Empty Initially)
```javascript
// Path: transport/{transportId}/bookings
// Documents will be created automatically when users book seats
// No manual setup needed - just ensure the subcollection path exists
```

## 📱 **Alternative: Setup via Flutter Code**

### Add this to your admin panel for quick setup:
```dart
// Quick setup function for initial data
Future<void> setupInitialData() async {
  final firestore = FirebaseFirestore.instance;
  
  // 1. Create sample event
  final eventRef = await firestore.collection('events').add({
    'title': 'Sunday Ziyarat - Mazar-e-Fakhri',
    'createdBy': Get.find<AuthController>().uid,
    'eventDate': Timestamp.fromDate(DateTime(2026, 5, 10, 8, 0)),
    'location': 'Galiyat, Dohad',
    'rsvpEnabled': true,
    'attendanceEnabled': true,
    'transportRequired': true,
    'transportCapacity': 50,
    'transportStatus': 'planning',
    'transportNotes': 'Departing from Masjid at 6:00 AM',
    'createdAt': Timestamp.now(),
  });
  
  // 2. Create transport for this event
  await firestore.collection('transport').add({
    'eventId': eventRef.id,
    'teamId': Get.find<AuthController>().teamId,
    'vehicleLabel': 'TC Bus 1 - Sunday Ziyarat',
    'driverName': 'Ahmed',
    'vehicleType': 'cruiser',
    'route': 'Masjid Dohad → Galiyat',
    'status': 'active',
    'departureTime': Timestamp.fromDate(DateTime(2026, 5, 10, 6, 0)),
    'returnTime': Timestamp.fromDate(DateTime(2026, 5, 10, 18, 0)),
    'pickupPoint': 'Main Masjid, Dohad',
    'contactPerson': 'Ahmed - +91 98765 43210',
    'priority': 'high',
    'totalCapacity': 11,
    'currentBookings': 0,
    'waitingList': 0,
    'createdAt': Timestamp.now(),
    'updatedAt': Timestamp.now(),
  });
  
  Get.snackbar('Setup Complete', 'Initial event and transport created');
}
```

## 🔧 **Update Existing Models**

### 1. Update TransportModel
```dart
// Add these fields to transport_model.dart
class TransportModel {
  // ... existing fields ...
  
  // 🆕 Event linkage
  final String eventId;
  
  // 🆕 Transport management
  final DateTime? departureTime;
  final DateTime? returnTime;
  final String? pickupPoint;
  final String? contactPerson;
  final String priority;
  
  // 🆕 Capacity tracking
  final int currentBookings;
  final int waitingList;
  
  TransportModel({
    required this.eventId,        // 🆕 Required
    // ... existing parameters ...
    this.departureTime,
    this.returnTime,
    this.pickupPoint,
    this.contactPerson,
    this.priority = 'medium',
    this.currentBookings = 0,
    this.waitingList = 0,
  });
}
```

### 2. Update EventModel
```dart
// Add transport fields to event_model.dart
class EventModel {
  // ... existing fields ...
  
  // 🆕 Transport fields
  final bool transportRequired;
  final int transportCapacity;
  final String transportStatus;
  final String? transportNotes;
  
  EventModel({
    // ... existing parameters ...
    this.transportRequired = false,
    this.transportCapacity = 0,
    this.transportStatus = 'none',
    this.transportNotes,
  });
}
```

## 🎯 **Security Rules Update**

Add to your existing firestore.rules:

```javascript
// Inside your teams collection rules
match /events/{eventId} {
  allow read: if isSignedIn() && isActive();
  allow create: if isSupervisorOrLeader();
  allow update: if isSupervisorOrLeader();
  allow delete: if isLeader();
}

match /transport/{transportId} {
  allow read: if isSignedIn() && isActive();
  allow create: if isSupervisorOrLeader();
  allow update: if isSupervisorOrLeader();
  allow delete: if isLeader();
  
  // 🆕 Bookings subcollection
  match /bookings/{seatId} {
    allow read: if request.auth != null;
    allow create: if request.auth != null
      && request.resource.data.userId == request.auth.uid
      && !userAlreadyBooked(transportId);
    allow delete: if request.auth.uid == resource.data.userId
      || isSupervisorOrLeader();
    allow update: if false;
  }
  
  // 🆕 Waiting list subcollection
  match /waitingList/{userId} {
    allow read: if request.auth != null;
    allow create: if request.auth != null
      && request.resource.data.userId == request.auth.uid;
    allow delete: if request.auth.uid == resource.data.userId
      || isSupervisorOrLeader();
    allow update: if false;
  }
}
```

## ⚡ **Quick Test**

After setup, test with:

1. **Create Event** via admin panel
2. **Create Transport** linked to event  
3. **Book Seat** as regular user
4. **Check Real-time Updates** in Firestore console

## 🚨 **Important Notes**

1. **Index Required**: Create composite index for (eventId, status) queries
2. **Data Migration**: Existing transports need eventId field added
3. **Testing**: Test with different user roles (admin, supervisor, member)
4. **Backup**: Always backup before schema changes
