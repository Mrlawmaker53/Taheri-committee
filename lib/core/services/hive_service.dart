import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';

class HiveService {
  static const String _usersBox = 'users_box';
  static const String _eventsBox = 'events_box';
  static const String _announcementsBox = 'announcements_box';
  static const String _contributionsBox = 'contributions_box';
  static const String _pendingWritesBox = 'pending_writes_box';

  static Future<void> init() async {
    await Hive.openBox<Map>(_usersBox);
    await Hive.openBox<Map>(_eventsBox);
    await Hive.openBox<Map>(_announcementsBox);
    await Hive.openBox<Map>(_contributionsBox);
    await Hive.openBox<Map>(_pendingWritesBox);
  }

  static Future<void> cacheUser(UserModel user) async {
    final box = Hive.box<Map>(_usersBox);
    await box.put(user.uid, {
      'uid': user.uid,
      'fullName': user.fullName,
      'email': user.email,
      'role': user.role,
      'teamId': user.teamId,
      'avatarUrl': user.avatarUrl,
      'isActive': user.isActive,
      'mobile': user.mobile,
      'createdAt': user.createdAt.millisecondsSinceEpoch,
      // New fields
      'itsNo': user.itsNo,
      'dateOfBirth': user.dateOfBirth,
      'gender': user.gender,
      'address': user.address,
      'professional': user.professional,
      'skill': user.skill,
      'pickupPoint': user.pickupPoint,
      'profileUrl': user.profileUrl,
      'updatedAt': user.updatedAt.millisecondsSinceEpoch,
    });
  }

  static UserModel? getCachedUser(String uid) {
    final box = Hive.box<Map>(_usersBox);
    final data = box.get(uid);
    if (data == null) return null;
    final map = Map<String, dynamic>.from(data);
    return UserModel(
      uid: map['uid'] ?? uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'member',
      teamId: map['teamId'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      isActive: map['isActive'] ?? true,
      mobile: map['mobile']?.toString() ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      // New fields with defaults
      itsNo: map['itsNo'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      gender: map['gender'] ?? '',
      address: map['address'] ?? '',
      professional: map['professional'] ?? '',
      skill: map['skill'] ?? '',
      pickupPoint: map['pickupPoint'] ?? '',
      profileUrl: map['profileUrl'] ?? '',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          map['updatedAt'] ?? map['createdAt'] ?? 0),
    );
  }

  static Future<void> cacheEvent(String id, Map<String, dynamic> data) async {
    final box = Hive.box<Map>(_eventsBox);
    await box.put(id, data);
  }

  static List<Map<String, dynamic>> getCachedEvents() {
    final box = Hive.box<Map>(_eventsBox);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> cacheAnnouncement(
      String id, Map<String, dynamic> data) async {
    final box = Hive.box<Map>(_announcementsBox);
    await box.put(id, data);
  }

  static List<Map<String, dynamic>> getCachedAnnouncements() {
    final box = Hive.box<Map>(_announcementsBox);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> cacheContribution(
      String id, Map<String, dynamic> data) async {
    final box = Hive.box<Map>(_contributionsBox);
    await box.put(id, data);
  }

  static List<Map<String, dynamic>> getCachedContributions(String memberId) {
    final box = Hive.box<Map>(_contributionsBox);
    return box.values
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => e['memberId'] == memberId)
        .toList();
  }

  static Future<void> addPendingWrite(Map<String, dynamic> write) async {
    final box = Hive.box<Map>(_pendingWritesBox);
    await box.add(write);
  }

  static List<Map<String, dynamic>> getPendingWrites() {
    final box = Hive.box<Map>(_pendingWritesBox);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> clearPendingWrites() async {
    await Hive.box<Map>(_pendingWritesBox).clear();
  }
}
