# Seat Booking System Fix for Member Role Access

## Problem Identified

The SeatMapScreen is breaking for member role users because the required Firebase collections and transport data are missing. The seat booking system expects a specific data structure that hasn't been set up yet.

## Root Cause Analysis

### Missing Firebase Collections:
1. **Main Transport Collection**: `transport/{transportId}` documents
2. **Bookings Subcollection**: `transport/{transportId}/bookings/{seatId}` 
3. **Waiting List Subcollection**: `transport/{transportId}/waitingList/{userId}`

### Required Data Structure:
```javascript
transport/{transportId}
├── vehicleLabel: "Toyota Cruiser - Main Vehicle"
├── driverName: "Driver Name"  
├── route: "Route Description"
├── vehicleType: "cruiser" | "eeco"
├── teamId: "team_001"
├── status: "active"
├── eventId: "event_001"
├── eventTitle: "Event Name"
├── departureTime: timestamp
├── returnTime: timestamp
├── pickupPoint: "Pickup Location"
├── contactPerson: "Contact Name"
├── priority: "high" | "medium" | "low"
├── currentBookings: 0
├── waitingList: 0
├── createdAt: timestamp
├── updatedAt: timestamp
```

## Quick Fix Solutions

### Option 1: Manual Setup (Fastest)
1. Go to Firebase Console → Firestore Database
2. Create these sample transport documents:

#### Transport 1 (Cruiser)
**Document ID**: `transport_001` in `transport` collection
```json
{
  "vehicleLabel": "Toyota Cruiser - Main Vehicle",
  "driverName": "Ahmed Hassan", 
  "route": "Central Mosque → Event Venue",
  "vehicleType": "cruiser",
  "teamId": "team_001",
  "status": "active",
  "eventId": "event_001",
  "eventTitle": "Friday Prayers Transport",
  "departureTime": "2026-05-09T17:00:00Z",
  "returnTime": "2026-05-09T21:00:00Z", 
  "pickupPoint": "Central Mosque Parking",
  "contactPerson": "Transport Coordinator",
  "priority": "high",
  "currentBookings": 0,
  "waitingList": 0,
  "createdAt": "2026-05-09T12:00:00Z",
  "updatedAt": "2026-05-09T12:00:00Z"
}
```

#### Transport 2 (Eeco)
**Document ID**: `transport_002` in `transport` collection
```json
{
  "vehicleLabel": "Suzuki Eeco - Backup Vehicle",
  "driverName": "Mohammed Ali",
  "route": "Secondary Route → Event Venue", 
  "vehicleType": "eeco",
  "teamId": "team_001",
  "status": "active",
  "eventId": "event_001",
  "eventTitle": "Friday Prayers Transport",
  "departureTime": "2026-05-09T17:30:00Z",
  "returnTime": "2026-05-09T21:30:00Z",
  "pickupPoint": "Secondary Pickup Point", 
  "contactPerson": "Backup Coordinator",
  "priority": "medium",
  "currentBookings": 0,
  "waitingList": 0,
  "createdAt": "2026-05-09T12:00:00Z",
  "updatedAt": "2026-05-09T12:00:00Z"
}
```

3. For each transport document, create empty subcollections:
   - `bookings` (will be populated when users book seats)
   - `waitingList` (will be populated when users join waiting list)

### Option 2: Automated Setup (Recommended)
Use the provided setup script:

```bash
# Navigate to functions directory
cd functions

# Install dependencies if needed
npm install

# Run the setup script
node setupTransport.js
```

### Option 3: In-App Setup
Add this to your admin panel for supervisors/leaders:

```dart
import '../core/services/transport_setup_service.dart';

// Call this from admin panel
await TransportSetupService.initializeSampleData();
```

## Verification Steps

After setting up the data:

1. **Test with Member Account**:
   - Login as a member user
   - Navigate to Transport section
   - Click on a transport vehicle
   - Should see the SeatMapScreen with seat layout
   - Should be able to select and book available seats

2. **Test Booking Flow**:
   - Member selects an available seat (green)
   - Confirm booking dialog appears
   - Booking is saved to `bookings` subcollection
   - Seat shows as booked (red with user info)

3. **Test Waiting List**:
   - If all seats are booked, member can join waiting list
   - Added to `waitingList` subcollection
   - Notified when seat becomes available

## Role-Based Access

### Members Can:
- ✅ View transport list for their team
- ✅ Access SeatMapScreen
- ✅ See available/booked seats
- ✅ Book available seats
- ✅ Join waiting list
- ✅ Cancel their own bookings

### Supervisors/Leaders Can:
- ✅ All member permissions
- ✅ Create new transport documents
- ✅ View seat manifest (admin button in SeatMapScreen)
- ✅ Manage any user's bookings
- ✅ Access transport management

## Common Issues & Fixes

### Issue: "Transport Not Found" error
**Cause**: No transport documents exist or teamId mismatch
**Fix**: Create transport documents with correct teamId

### Issue: "Permission denied" for members  
**Cause**: Firestore rules blocking access
**Fix**: Ensure user has correct role in `users` collection

### Issue: Empty seat map
**Cause**: Subcollections don't exist or transport data missing
**Fix**: Verify transport document has all required fields

### Issue: Booking not working
**Cause**: User not authenticated or missing permissions
**Fix**: Check user login status and Firestore rules

## Files Modified

1. **SeatMapScreen**: Added error handling for missing transport data
2. **TransportSetupService**: New service for automated data setup
3. **setupTransport.js**: Firebase script for bulk initialization
4. **setup_transport_data.md**: Manual setup guide

## Support

If you continue to experience issues:

1. Check Firebase Console that collections exist
2. Verify user roles in `users` collection
3. Test with different user roles (member, supervisor, leader)
4. Check browser console for any JavaScript errors
5. Ensure Firestore rules are properly deployed

The seat booking system should now work properly for all member role users! 🎉
