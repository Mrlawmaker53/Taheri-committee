# Firebase Transport Data Setup Guide

## Required Collections Structure

### 1. Main Transport Collection
```
transport/{transportId}
├── id: "transport_001"
├── vehicleLabel: "Toyota Cruiser - 001"
├── driverName: "Driver Name"
├── route: "Route Description"
├── vehicleType: "cruiser"
├── teamId: "your_team_id"
├── eventId: "event_001"
├── eventTitle: "Event Name"
├── departureTime: timestamp
├── returnTime: timestamp
├── pickupPoint: "Pickup Location"
├── contactPerson: "Contact Name"
├── priority: "medium"
├── createdAt: timestamp
├── updatedAt: timestamp
```

### 2. Bookings Subcollection
```
transport/{transportId}/bookings/{seatId}
├── seatId: "seat_01"
├── userId: "user_uid"
├── displayName: "User Name"
├── avatarUrl: "profile_image_url"
├── bookedAt: timestamp
```

### 3. Waiting List Subcollection
```
transport/{transportId}/waitingList/{userId}
├── userId: "user_uid"
├── displayName: "User Name"
├── transportId: "transport_001"
├── requestedAt: timestamp
├── priority: "medium"
```

## Manual Setup Steps

### Step 1: Create Sample Transport Document
```javascript
// In Firebase Console -> Firestore Database
// Create a document in "transport" collection with ID "transport_001"

{
  "vehicleLabel": "Toyota Cruiser - Main Vehicle",
  "driverName": "Ahmed Hassan",
  "route": "Central Mosque → Event Venue",
  "vehicleType": "cruiser",
  "teamId": "team_001", // Replace with actual team ID
  "eventId": "event_001",
  "eventTitle": "Friday Prayers Transport",
  "departureTime": "2026-05-09T17:00:00Z",
  "returnTime": "2026-05-09T21:00:00Z",
  "pickupPoint": "Central Mosque Parking",
  "contactPerson": "Transport Coordinator",
  "priority": "high",
  "createdAt": "2026-05-09T12:00:00Z",
  "updatedAt": "2026-05-09T12:00:00Z",
  "isActive": true
}
```

### Step 2: Initialize Empty Subcollections
For the transport document created above, add these subcollections:

#### Bookings Subcollection
- Create subcollection "bookings"
- Initially empty (users will book seats dynamically)

#### Waiting List Subcollection  
- Create subcollection "waitingList"
- Initially empty (users will join waiting list dynamically)

### Step 3: Verify Access
1. Member users should be able to:
   - View the transport list
   - Access SeatMapScreen
   - See available seats
   - Book seats (if available)
   - Join waiting list (if no seats available)

2. Supervisor/Leader users should additionally be able to:
   - Create new transport documents
   - View seat manifest
   - Manage bookings

## Quick Test Data Setup Script

If you have Firebase CLI access, you can use this script:

```bash
# Create sample transport data
firebase firestore:import --collection-ids=transport transport_sample.json
```

## Common Issues & Fixes

### Issue 1: "Transport not found" error
**Fix**: Ensure transport documents exist and user's teamId matches

### Issue 2: "Permission denied" for members
**Fix**: Check Firestore rules and ensure user has correct role in users collection

### Issue 3: Empty seat map
**Fix**: Ensure transport document has correct vehicleType and subcollections exist

### Issue 4: Booking not working
**Fix**: Ensure user is authenticated and has proper permissions in Firestore rules

## Verification

After setup, test with a member account:
1. Navigate to transport section
2. Click on a transport vehicle
3. Should see seat map with available seats
4. Should be able to select and book a seat
