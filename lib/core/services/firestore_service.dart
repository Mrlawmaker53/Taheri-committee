import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/team_model.dart';
import '../models/event_model.dart';
import '../models/contribution_model.dart';
import '../models/group_request_model.dart';
import '../models/transfer_request_model.dart';
import '../models/transport_model.dart';
import '../models/notification_model.dart';
import '../models/activity_log_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference get users => _db.collection('users');
  static CollectionReference get teams => _db.collection('teams');
  static CollectionReference get events => _db.collection('events');
  static CollectionReference get rsvp => _db.collection('rsvp');
  static CollectionReference get attendance => _db.collection('attendance');
  static CollectionReference get contributions =>
      _db.collection('contributions');
  static CollectionReference get groupRequests =>
      _db.collection('group_requests');
  static CollectionReference get transferRequests =>
      _db.collection('transfer_requests');
  static CollectionReference get transport => _db.collection('transport');
  static CollectionReference get notifications =>
      _db.collection('notifications');
  static CollectionReference get activityLogs =>
      _db.collection('activity_logs');
  static CollectionReference get announcements =>
      _db.collection('announcements');

  static Future<UserModel?> getUser(String uid) async {
    final doc = await users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  static Future<void> createUser(UserModel user) async {
    await users.doc(user.uid).set(user.toMap());
  }

  static Future<TeamModel?> getTeam(String teamId) async {
    final doc = await teams.doc(teamId).get();
    if (!doc.exists) return null;
    return TeamModel.fromFirestore(doc);
  }

  static Stream<List<UserModel>> streamTeamMembers(String teamId) {
    return users
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  static Stream<List<TeamModel>> streamAllTeams() {
    return teams
        .orderBy('teamName')
        .snapshots()
        .map((s) => s.docs.map((d) => TeamModel.fromFirestore(d)).toList());
  }

  static Stream<List<EventModel>> streamEvents() {
    return events
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => EventModel.fromFirestore(d)).toList());
  }

  static Stream<List<ContributionModel>> streamMemberContributions(
      String memberId) {
    return contributions
        .where('memberId', isEqualTo: memberId)
        .orderBy('raisedAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ContributionModel.fromFirestore(d)).toList());
  }

  static Stream<List<ContributionModel>> streamPendingContributions(
      String supervisorId) {
    return contributions
        .where('supervisorId', isEqualTo: supervisorId)
        .where('status', isEqualTo: 'pending')
        .orderBy('raisedAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ContributionModel.fromFirestore(d)).toList());
  }

  static Stream<List<ContributionModel>> streamTeamContributions(
      String teamId) {
    return contributions
        .where('teamId', isEqualTo: teamId)
        .orderBy('raisedAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ContributionModel.fromFirestore(d)).toList());
  }

  static Stream<List<GroupRequestModel>> streamGroupRequests() {
    return groupRequests
        .where('status', isEqualTo: 'pending_leader')
        .orderBy('raisedAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => GroupRequestModel.fromFirestore(d)).toList());
  }

  static Stream<List<TransferRequestModel>> streamTransferRequests(
      {String? supervisorStatus, String? leaderStatus}) {
    Query q = transferRequests;
    if (supervisorStatus != null) {
      q = q.where('status', isEqualTo: supervisorStatus);
    }
    if (leaderStatus != null) {
      q = q.where('status', isEqualTo: leaderStatus);
    }
    return q.orderBy('createdAt', descending: true).snapshots().map((s) =>
        s.docs.map((d) => TransferRequestModel.fromFirestore(d)).toList());
  }

  static Stream<List<TransportModel>> streamTransport({String? teamId}) {
    Query q = transport;
    if (teamId != null) q = q.where('teamId', isEqualTo: teamId);
    return q.snapshots().map(
        (s) => s.docs.map((d) => TransportModel.fromFirestore(d)).toList());
  }

  static Stream<List<NotificationModel>> streamNotifications(String userId) {
    return notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => NotificationModel.fromFirestore(d)).toList());
  }

  static Stream<List<ActivityLogModel>> streamActivityLogs(
      {String? actionFilter, int limit = 100}) {
    Query q = activityLogs.orderBy('timestamp', descending: true).limit(limit);
    return q.snapshots().map(
        (s) => s.docs.map((d) => ActivityLogModel.fromFirestore(d)).toList());
  }

  static Future<String> createContribution(Map<String, dynamic> data) async {
    final doc = await contributions.add(data);
    return doc.id;
  }

  static Future<void> updateContribution(
      String id, Map<String, dynamic> data) async {
    await contributions.doc(id).update(data);
  }

  static Future<String> createGroupRequest(Map<String, dynamic> data) async {
    final doc = await groupRequests.add(data);
    return doc.id;
  }

  static Future<void> updateGroupRequest(
      String id, Map<String, dynamic> data) async {
    await groupRequests.doc(id).update(data);
  }

  static Future<String> createTransferRequest(Map<String, dynamic> data) async {
    final doc = await transferRequests.add(data);
    return doc.id;
  }

  static Future<void> updateTransferRequest(
      String id, Map<String, dynamic> data) async {
    await transferRequests.doc(id).update(data);
  }

  static Future<void> createEvent(Map<String, dynamic> data) async {
    await events.add(data);
  }

  static Future<void> createAnnouncement(Map<String, dynamic> data) async {
    await announcements.add(data);
  }

  static Future<void> updateUserRole(String uid, String role) async {
    await users.doc(uid).update({'role': role});
  }

  static Future<void> updateUserTeam(String uid, String teamId) async {
    await users.doc(uid).update({'teamId': teamId});
  }

  static WriteBatch batch() => _db.batch();
}
