# 🚐 Pickup Collection Setup Guide

## 📋 Overview
This guide shows you how to create the `pickups` collection in Firebase Firestore and manage pickup locations for your app.

## 🔥 Step 1: Create Pickup Collection in Firebase

### **Method 1: Firebase Console (Recommended)**

1. **Go to Firebase Console**
   - Open [Firebase Console](https://console.firebase.google.com)
   - Select your project
   - Go to **Firestore Database**

2. **Create Collection**
   - Click **"Start collection"** or **"Add collection"**
   - Collection ID: `pickups`
   - Click **"Next"**

3. **Add First Document**
   - Document ID: Leave as **"Auto ID"**
   - Add the following fields:

   ```javascript
// Sample Pickup Location
{
  name: "Central Mosque",
  address: "123 Main Street, City Center",
  contact: "+1234567890",
  isActive: true,
  createdAt: timestamp
}
```

4. **Field Types:**
   - `name`: **String** - Pickup location name
   - `address`: **String** - Full address
   - `contact`: **String** - Contact phone number
   - `isActive`: **Boolean** - Whether location is active
   - `createdAt`: **Timestamp** - When created (auto-generated)

### **Method 2: Using the App**
1. Run the app as admin
2. Go to **Admin Panel** → **Manage Pickups**
3. Click **+ (Add)** button
4. Fill in pickup details
5. Click **"Add Location"**

---

## 🔥 Step 2: Add Sample Pickup Locations

### **Sample Data to Add:**

```javascript
// Document 1
{
  name: "Central Mosque",
  address: "123 Main Street, City Center",
  isActive: true,
  createdAt: timestamp
}

// Document 2
{
  name: "North Station",
  address: "456 North Avenue, District 1",
  isActive: true,
  createdAt: timestamp
}

// Document 3
{
  name: "South Plaza",
  address: "789 South Road, District 2",
  isActive: true,
  createdAt: timestamp
}

// Document 4
{
  name: "East Gate",
  address: "321 East Boulevard, District 3",
  isActive: true,
  createdAt: timestamp
}

// Document 5
{
  name: "West Mall",
  address: "654 West Street, District 4",
  isActive: true,
  createdAt: timestamp
}
```

---

## 🔥 Step 3: Update Firestore Rules

Add these rules to your `firestore.rules` file:

```javascript
// ─── pickups ────────────────────────────────────────────────────────────────
match /pickups/{pickupId} {
  allow read: if isSignedIn() && isActive();
  allow create: if isSignedIn() && isActive() && isSupervisorOrLeader();
  allow update: if isSignedIn() && isActive() && isSupervisorOrLeader();
  allow delete: if isSignedIn() && isActive() && isLeader();
}
```

### **Where to Add Rules:**
1. Open `firestore.rules` in your project
2. Find the section with other collection rules
3. Add the pickups rules section
4. Deploy the rules

---

## 🔥 Step 4: Test the Feature

### **Testing Steps:**

1. **Add Pickup Location**
   - Go to Admin Panel → Manage Pickups
   - Click + button
   - Fill in all fields
   - Click "Add Location"
   - ✅ Should see success message

2. **Edit Pickup Location**
   - Click on any pickup tile
   - Modify details
   - Click "Update Location"
   - ✅ Should see success message

3. **Delete Pickup Location**
   - Click menu (⋮) on pickup tile
   - Select "Delete"
   - Confirm deletion
   - ✅ Should see success message

4. **Search Pickup Locations**
   - Use search bar
   - Type location name or address
   - ✅ Should filter results

5. **Test in User Form**
   - Go to Admin Panel → Manage Members
   - Click + to add user
   - ✅ Pickup dropdown should show locations

---

## 🔥 Step 5: Advanced Features

### **Bulk Import (Optional)**
For importing multiple pickup locations at once:

```javascript
// Use Firebase Console → Import JSON
[
  {
    "name": "Central Mosque",
    "address": "123 Main Street, City Center",
    "contact": "+1234567890",
    "isActive": true
  },
  {
    "name": "North Station", 
    "address": "456 North Avenue, District 1",
    "contact": "+1234567891",
    "isActive": true
  }
]
```

### **Geolocation (Future Enhancement)**
You can extend the pickup collection with:
```javascript
{
  name: "Central Mosque",
  address: "123 Main Street, City Center",
  contact: "+1234567890",
  isActive: true,
  createdAt: timestamp,
  // Future fields
  latitude: 40.7128,
  longitude: -74.0060,
  radius: 500, // meters
  capacity: 50
}
```

---

## 🔥 Step 6: Troubleshooting

### **Common Issues:**

1. **Pickup Dropdown Empty**
   - ✅ Check if pickups collection exists
   - ✅ Verify Firestore rules allow reading
   - ✅ Ensure user is authenticated

2. **Can't Add Pickup**
   - ✅ Check user role (must be supervisor/leader)
   - ✅ Verify Firestore rules allow create
   - ✅ Check network connection

3. **Delete Not Working**
   - ✅ Check user role (must be leader)
   - ✅ Verify Firestore rules allow delete
   - ✅ Check if pickup is referenced by users

### **Debug Steps:**
1. Check Firebase Console → Firestore → Data
2. Verify collection name is exactly `pickups`
3. Check Firestore Rules tab for errors
4. Look at browser console for JavaScript errors

---

## 🔥 Step 7: Best Practices

### **Data Quality:**
- ✅ Use consistent naming (Title Case)
- ✅ Include complete addresses
- ✅ Use valid phone numbers
- ✅ Keep isActive field accurate

### **Security:**
- ✅ Only supervisors/leaders can modify
- ✅ Regular users can only read
- ✅ Only leaders can delete
- ✅ Validate input data

### **Performance:**
- ✅ Limit to 50-100 pickup locations
- ✅ Use indexes for large datasets
- ✅ Cache frequently accessed data

---

## 🎯 Summary

### **✅ What You Get:**
- **Complete pickup management system**
- **Add, edit, delete pickup locations**
- **Search and filter functionality**
- **Integration with user registration**
- **Role-based permissions**
- **Professional UI with Material Design**

### **🚀 Ready to Use:**
1. Create `pickups` collection in Firebase
2. Add sample pickup locations
3. Update Firestore rules
4. Test the management interface
5. Start using in user registration

### **🔧 Files Updated:**
- `lib/features/admin/user_manage_screen.dart` - Added pickup dropdown
- `lib/features/admin/admin_controller.dart` - Updated user creation
- `lib/features/admin/pickup_manage_screen.dart` - New pickup management
- `lib/features/admin/admin_panel_screen.dart` - Added pickup tile

**🎉 Your pickup management system is now ready!** 🚐✨
