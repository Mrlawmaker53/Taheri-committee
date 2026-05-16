import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String role;
  final String teamId;
  final String avatarUrl;
  final bool isActive;
  final String mobile;
  final DateTime createdAt;

  // Additional fields for detailed user information
  final String itsNo;
  final String dateOfBirth;
  final String gender;
  final String address;
  final String professional;
  final String skill;
  final String pickupPoint;
  final String profileUrl;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.teamId,
    required this.avatarUrl,
    required this.isActive,
    required this.mobile,
    required this.createdAt,
    required this.itsNo,
    required this.dateOfBirth,
    required this.gender,
    required this.address,
    required this.professional,
    required this.skill,
    required this.pickupPoint,
    required this.profileUrl,
    required this.updatedAt,
  });

  bool get isLeader => role == 'leader' || role == 'admin';
  bool get isSupervisor => role == 'supervisor';
  bool get isMember => role == 'member';
  bool get isSupervisorOrLeader => isSupervisor || isLeader;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'member',
      teamId: data['teamId'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      isActive: data['isActive'] ?? true,
      mobile: data['mobile']?.toString() ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      itsNo: data['itsNo'] ?? '',
      dateOfBirth: data['dateOfBirth'] ?? '',
      gender: data['gender'] ?? '',
      address: data['address'] ?? '',
      professional: data['professional'] ?? '',
      skill: data['skill'] ?? '',
      pickupPoint: data['pickupPoint'] ?? '',
      profileUrl: data['profileUrl'] ?? '',
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'member',
      teamId: data['teamId'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      isActive: data['isActive'] ?? true,
      mobile: data['mobile']?.toString() ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      itsNo: data['itsNo'] ?? '',
      dateOfBirth: data['dateOfBirth'] ?? '',
      gender: data['gender'] ?? '',
      address: data['address'] ?? '',
      professional: data['professional'] ?? '',
      skill: data['skill'] ?? '',
      pickupPoint: data['pickupPoint'] ?? '',
      profileUrl: data['profileUrl'] ?? '',
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'role': role,
      'teamId': teamId,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
      'mobile': mobile,
      'createdAt': Timestamp.fromDate(createdAt),
      'itsNo': itsNo,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'address': address,
      'professional': professional,
      'skill': skill,
      'pickupPoint': pickupPoint,
      'profileUrl': profileUrl,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? role,
    String? teamId,
    String? avatarUrl,
    bool? isActive,
    String? mobile,
    DateTime? createdAt,
    String? itsNo,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? professional,
    String? skill,
    String? pickupPoint,
    String? profileUrl,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      teamId: teamId ?? this.teamId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      mobile: mobile ?? this.mobile,
      createdAt: createdAt ?? this.createdAt,
      itsNo: itsNo ?? this.itsNo,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      professional: professional ?? this.professional,
      skill: skill ?? this.skill,
      pickupPoint: pickupPoint ?? this.pickupPoint,
      profileUrl: profileUrl ?? this.profileUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
