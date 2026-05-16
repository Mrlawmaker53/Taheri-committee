import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Seeds Firestore with a minimal demo dataset so that lists in the app are
/// not empty during development.
///
/// Creates:
///   - 1 team
///   - 3 users (leader, supervisor, member) all linked to that team
///   - 2 events
///   - 1 announcement
///
/// Returns a short summary string suitable for showing in a snackbar.
class SeedData {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<String> seedDemoData() async {
    final batch = _db.batch();
    final now = Timestamp.now();

    // Team
    final teamRef = _db.collection('teams').doc('demo_team');
    batch.set(teamRef, {
      'teamId': 'demo_team',
      'teamName': 'Demo Team',
      'supervisorId': 'demo_supervisor',
      'leaderId': 'demo_leader',
      'memberCount': 3,
      'createdAt': now,
    });

    // Users
    final users = [
      {
        'uid': 'demo_leader',
        'fullName': 'Demo Leader',
        'email': 'leader@demo.local',
        'role': 'leader',
        'teamId': 'demo_team',
        'avatarUrl': null,
        'isActive': true,
        'createdAt': now,
      },
      {
        'uid': 'demo_supervisor',
        'fullName': 'Demo Supervisor',
        'email': 'supervisor@demo.local',
        'role': 'supervisor',
        'teamId': 'demo_team',
        'avatarUrl': null,
        'isActive': true,
        'createdAt': now,
      },
      {
        'uid': 'demo_member',
        'fullName': 'Demo Member',
        'email': 'member@demo.local',
        'role': 'member',
        'teamId': 'demo_team',
        'avatarUrl': null,
        'isActive': true,
        'createdAt': now,
      },
    ];
    for (final u in users) {
      batch.set(_db.collection('users').doc(u['uid'] as String), u);
    }

    // Events
    final eventsCol = _db.collection('events');
    final ev1 = eventsCol.doc();
    final ev2 = eventsCol.doc();
    batch.set(ev1, {
      'eventId': ev1.id,
      'title': 'Weekly Majlis',
      'createdBy': 'demo_leader',
      'eventDate':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
      'location': 'Community Hall',
      'rsvpEnabled': true,
      'attendanceEnabled': true,
    });
    batch.set(ev2, {
      'eventId': ev2.id,
      'title': 'Community Cleanup',
      'createdBy': 'demo_leader',
      'eventDate':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 10))),
      'location': 'Main Square',
      'rsvpEnabled': true,
      'attendanceEnabled': false,
    });

    // Announcement
    final annCol = _db.collection('announcements');
    final ann1 = annCol.doc();
    batch.set(ann1, {
      'announcementId': ann1.id,
      'title': 'Welcome to Taheri Committee',
      'body':
          'This is a demo announcement seeded from the admin panel. Replace with real content.',
      'createdBy': 'demo_leader',
      'createdAt': now,
      'audience': 'all',
    });

    try {
      await batch.commit();
      debugPrint('✅ Seed demo data committed');
      return '1 team, 3 users, 2 events, 1 announcement seeded.';
    } catch (e) {
      debugPrint('❌ Seed failed: $e');
      rethrow;
    }
  }
}
