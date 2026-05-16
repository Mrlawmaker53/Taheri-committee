# Transport Feature Setup Manual

## 🚨 Issue: Transport Loading Error for Members

### **Problem**
The transport/seat booking feature shows a loading error for member role users because:
1. No transport documents exist in Firebase
2. Members need transport data to be able to book seats
3. Firebase permissions are correct but there's no data to load

---

## 🛠️ **SOLUTION 1: Automatic Setup (Recommended)**

### For Admins/Supervisors:
1. **Login as Admin or Supervisor**
2. **Navigate to Transport screen**
3. **Click "Initialize Sample Data" button** (appears when no transport exists)
4. **Wait for success message**

This will automatically create:
- ✅ 2 sample transport vehicles (Cruiser & Eeco)
- ✅ Required subcollections (`bookings` and `waitingList`)
- ✅ Proper team-based permissions

---

## 🔧 **SOLUTION 2: Manual Firebase Setup**

### Step 1: Create Transport Documents
Go to **Firebase Console → Firestore Database → transport collection**

#### Document 1: `transport_001`
```json
{
  "id": "transport_001",
  "vehicleLabel": "Toyota Cruiser - Main Vehicle",
  "driverName": "Ahmed Hassan",
  "route": "Main Pickup Point → Event Venue",
  "vehicleType": "cruiser",
  "teamId": "YOUR_TEAM_ID",
  "status": "active",
  "eventId": "event_001",
  "eventTitle": "Friday Prayers Transport",
  "departureTime": "2024-01-01T10:30:00Z",
  "returnTime": "2024-01-01T14:30:00Z",
  "pickupPoint": "Main Mosque Parking",
  "contactPerson": "Transport Coordinator",
  "priority": "high",
  "currentBookings": 0,
  "waitingList": 0,
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

#### Document 2: `transport_002`
```json
{
  "id": "transport_002",
  "vehicleLabel": "Suzuki Eeco - Backup Vehicle",
  "driverName": "Mohammed Ali",
  "route": "Secondary Route → Event Venue",
  "vehicleType": "eeco",
  "teamId": "YOUR_TEAM_ID",
  "status": "active",
  "eventId": "event_001",
  "eventTitle": "Friday Prayers Transport",
  "departureTime": "2024-01-01T10:45:00Z",
  "returnTime": "2024-01-01T14:45:00Z",
  "pickupPoint": "Secondary Pickup Point",
  "contactPerson": "Backup Coordinator",
  "priority": "medium",
  "currentBookings": 0,
  "waitingList": 0,
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

**⚠️ Important**: Replace `YOUR_TEAM_ID` with your actual team ID from the `teams` collection.

### Step 2: Create Subcollections (Optional but Recommended)

For each transport document, create these subcollections:

#### `transport/transport_001/bookings/` (Empty initially)
#### `transport/transport_001/waitingList/` (Empty initially)
#### `transport/transport_002/bookings/` (Empty initially)
#### `transport/transport_002/waitingList/` (Empty initially)

---

## 🎯 **Verification**

### After Setup:
1. **Refresh the app**
2. **Login as a member**
3. **Navigate to Transport screen**
4. **Should see transport vehicles** with "Book Seats" buttons
5. **Click "Book Seats"** to test seat booking functionality

### Expected Behavior:
- ✅ Members can view available transport
- ✅ Members can book specific seats
- ✅ Members can join waiting list if full
- ✅ Real-time seat availability updates
- ✅ Proper role-based permissions

---

## 🚀 **Testing the Full Flow**

### For Members:
1. View transport list
2. Click "Book Seats" on a transport
3. Select an available seat (green)
4. Confirm booking
5. See seat turn red (booked)
6. Try waiting list if all seats booked

### For Admins/Supervisors:
1. View transport management
2. Add new transport vehicles
3. Monitor seat bookings
4. Manage waiting lists

---

## 🔍 **Troubleshooting**

### Still Loading Error?
1. **Check teamId**: Ensure transport documents have correct `teamId`
2. **Check permissions**: Verify user is active and in correct team
3. **Check Firebase rules**: Ensure transport collection rules allow read access
4. **Refresh app**: Pull to refresh or restart app

### Can't Book Seats?
1. **Check subcollections**: Ensure `bookings` and `waitingList` exist
2. **Check user role**: Only members can book seats
3. **Check transport status**: Only `active` transports allow booking

---

## 📱 **Mobile App Features**

Once transport data is set up, members can:
- 🚌 View available transport vehicles
- 💺 Book specific seats in real-time
- ⏳ Join waiting lists when full
- 📍 See pickup points and routes
- 🕐 Check departure/return times
- 👥 View who booked which seats

---

## ✅ **Success Checklist**

- [ ] Transport documents created in Firebase
- [ ] Correct teamId assigned to transports
- [ ] Subcollections initialized (bookings, waitingList)
- [ ] Members can view transport list
- [ ] Members can book seats
- [ ] Real-time updates working
- [ ] No loading errors for members

**🎉 Your transport feature is now ready for members!**
