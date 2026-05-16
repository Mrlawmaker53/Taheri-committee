// Firebase Cloud Function to initialize transport data
// Run this once to set up the required collections

const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = getFirestore();

async function setupTransportData() {
  try {
    console.log('Setting up transport data...');

    // 1. Create sample transport document
    const transportId = 'transport_001';
    const transportData = {
      vehicleLabel: 'Toyota Cruiser - Main Vehicle',
      driverName: 'Ahmed Hassan',
      route: 'Central Mosque → Event Venue',
      vehicleType: 'cruiser',
      teamId: 'team_001', // Update with actual team ID
      eventId: 'event_001',
      eventTitle: 'Friday Prayers Transport',
      departureTime: new Date('2026-05-09T17:00:00Z'),
      returnTime: new Date('2026-05-09T21:00:00Z'),
      pickupPoint: 'Central Mosque Parking',
      contactPerson: 'Transport Coordinator',
      priority: 'high',
      createdAt: new Date(),
      updatedAt: new Date(),
      isActive: true
    };

    await db.collection('transport').doc(transportId).set(transportData);
    console.log(`✅ Created transport document: ${transportId}`);

    // 2. Initialize empty bookings subcollection (create a placeholder)
    const bookingsRef = db.collection('transport').doc(transportId).collection('bookings');
    // Just verify the subcollection exists by trying to read it
    const bookingsSnapshot = await bookingsRef.limit(1).get();
    console.log(`✅ Bookings subcollection is accessible`);

    // 3. Initialize empty waiting list subcollection (create a placeholder)
    const waitingListRef = db.collection('transport').doc(transportId).collection('waitingList');
    const waitingListSnapshot = await waitingListRef.limit(1).get();
    console.log(`✅ Waiting list subcollection is accessible`);

    // 4. Create a second transport for testing
    const transportId2 = 'transport_002';
    const transportData2 = {
      vehicleLabel: 'Suzuki Eeco - Backup Vehicle',
      driverName: 'Mohammed Ali',
      route: 'Secondary Route → Event Venue',
      vehicleType: 'eeco',
      teamId: 'team_001',
      eventId: 'event_001',
      eventTitle: 'Friday Prayers Transport',
      departureTime: new Date('2026-05-09T17:30:00Z'),
      returnTime: new Date('2026-05-09T21:30:00Z'),
      pickupPoint: 'Secondary Pickup Point',
      contactPerson: 'Backup Coordinator',
      priority: 'medium',
      createdAt: new Date(),
      updatedAt: new Date(),
      isActive: true
    };

    await db.collection('transport').doc(transportId2).set(transportData2);
    console.log(`✅ Created second transport document: ${transportId2}`);

    console.log('\n🎉 Transport data setup completed successfully!');
    console.log('\nNext steps:');
    console.log('1. Test with a member account in the Flutter app');
    console.log('2. Navigate to Transport section');
    console.log('3. Click on a vehicle to access SeatMapScreen');
    console.log('4. Verify seat booking works for members');

  } catch (error) {
    console.error('❌ Error setting up transport data:', error);
  }
}

// Run the setup
setupTransportData().then(() => {
  process.exit(0);
}).catch((error) => {
  console.error('Setup failed:', error);
  process.exit(1);
});
