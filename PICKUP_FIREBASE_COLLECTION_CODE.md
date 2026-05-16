# 🚐 Firebase Pickup Collection - 4 Main Fields Only

## 🔥 Firebase Collection Setup Code

### **Collection Name:** `pickups`

### **Document Structure (4 Main Fields Only):**

```javascript
// Firebase Firestore Collection: pickups
{
  name: "Central Mosque",        // String - Location name
  address: "123 Main Street",   // String - Full address  
  itsNo: "12345678",            // String - 8-digit ITS number
  isActive: true,               // Boolean - Active status
  createdAt: timestamp          // Timestamp - Auto-generated
}
```

---

## 🔥 Setup Code

### **Method 1: Firebase Console**

1. **Go to Firebase Console** → Firestore Database
2. **Click "Start collection"**
3. **Collection ID:** `pickups`
4. **Add first document** with these 4 fields:

```javascript
// Document 1
{
  name: "Central Mosque",
  address: "123 Main Street, City Center",
  itsNo: "12345678",
  isActive: true,
  createdAt: timestamp
}
```

### **Method 2: Bulk Import JSON**

```json
[
  {
    "name": "Central Mosque",
    "address": "123 Main Street, City Center",
    "itsNo": "12345678",
    "isActive": true
  },
  {
    "name": "North Station",
    "address": "456 North Avenue, District 1",
    "itsNo": "23456789",
    "isActive": true
  },
  {
    "name": "South Plaza",
    "address": "789 South Road, District 2",
    "itsNo": "34567890",
    "isActive": true
  },
  {
    "name": "East Gate",
    "address": "321 East Boulevard, District 3",
    "itsNo": "45678901",
    "isActive": true
  },
  {
    "name": "West Mall",
    "address": "654 West Street, District 4",
    "itsNo": "56789012",
    "isActive": true
  }
]
```

---

## 🔥 Firestore Rules

```javascript
match /pickups/{pickupId} {
  allow read: if isSignedIn() && isActive();
  allow create: if isSignedIn() && isActive() && isSupervisorOrLeader();
  allow update: if isSignedIn() && isActive() && isSupervisorOrLeader();
  allow delete: if isSignedIn() && isActive() && isLeader();
}
```

---

## 🔥 Flutter Code Reference

### **Add Pickup Function:**
```dart
Future<void> _addPickup({
  required String name,
  required String address,
  required String itsNo,
}) async {
  await _db.collection('pickups').add({
    'name': name,
    'address': address,
    'itsNo': itsNo,
    'isActive': true,
    'createdAt': Timestamp.now(),
  });
}
```

### **Update Pickup Function:**
```dart
Future<void> _updatePickup({
  required String docId,
  required String name,
  required String address,
  required String itsNo,
}) async {
  await _db.collection('pickups').doc(docId).update({
    'name': name,
    'address': address,
    'itsNo': itsNo,
    'updatedAt': Timestamp.now(),
  });
}
```

---

## 🎯 Summary

**✅ 5 Main Fields:**
1. `name` - String - Location name
2. `address` - String - Full address  
3. `itsNo` - String - 8-digit ITS number
4. `isActive` - Boolean - Active status
5. `createdAt` - Timestamp - Creation time

**✅ ITS No Validation:**
- Exactly 8 digits required
- Only numbers accepted
- Required field
- Auto-validated in forms

**✅ Clean & Simple Structure**
**✅ Ready for Production**
