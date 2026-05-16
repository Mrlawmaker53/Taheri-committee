import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/activity_log_service.dart';
import '../services/hive_service.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final Rx<User?> firebaseUser = Rx<User?>(null);
  final RxBool isLoggedIn = false.obs;
  final RxBool authReady = false.obs;
  final RxBool isProfileLoaded = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      currentUser.value = null;
      isLoggedIn.value = false;
      isProfileLoaded.value = false;
    } else {
      isLoggedIn.value = true;
      isProfileLoaded.value = false;
      debugPrint('✅ Auth state uid=${user.uid} email=${user.email}');
      await _loadUserData(user.uid);
      isProfileLoaded.value = true;
    }
    authReady.value = true;
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);
        currentUser.value = user;
        debugPrint('✅ Role loaded: ${user.role}');
        await HiveService.cacheUser(user);
      } else {
        debugPrint('⚠ No Firestore profile for uid=$uid');
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      final cached = HiveService.getCachedUser(uid);
      if (cached != null) currentUser.value = cached;
    }
  }

  Future<void> signIn(String email, String password) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      // Wait for profile so role/displayName are populated, then audit log.
      // Cloud Function `onAuthActivityLog` will fan out an FCM push to leaders.
      await Future.doWhile(() async {
        if (isProfileLoaded.value) return false;
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      }).timeout(const Duration(seconds: 5), onTimeout: () {});
      try {
        await ActivityLogService.log(
          action: 'login',
          targetId: uid,
          targetType: 'user',
          targetName: displayName,
          metadata: {
            'platform': kIsWeb ? 'web' : 'mobile',
          },
        );
      } catch (e) {
        debugPrint('login audit log failed: $e');
      }
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapAuthError(e.code);
      Get.snackbar(
        'Login Failed',
        errorMessage.value,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      errorMessage.value = 'Login failed. Please try again.';
      Get.snackbar(
        'Login Failed',
        errorMessage.value,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Google Sign-In
  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        isLoading.value = false;
        return; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Create/update user document in Firestore
        final userRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await userRef.get();

        if (!userDoc.exists) {
          // New user - create document
          await userRef.set({
            'fullName': user.displayName ?? '',
            'email': user.email ?? '',
            'avatarUrl': user.photoURL,
            'role': 'member', // Default role
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Existing user - update last login
          await userRef.update({
            'lastLoginAt': FieldValue.serverTimestamp(),
            'avatarUrl': user.photoURL, // Update avatar if changed
          });
        }

        // Wait for profile to load
        await Future.doWhile(() async {
          if (isProfileLoaded.value) return false;
          await Future.delayed(const Duration(milliseconds: 100));
          return true;
        }).timeout(const Duration(seconds: 5), onTimeout: () {});

        // Log activity
        try {
          await ActivityLogService.log(
            action: 'login',
            targetId: user.uid,
            targetType: 'user',
            targetName: displayName,
            metadata: {
              'platform': kIsWeb ? 'web' : 'mobile',
              'method': 'google_sign_in',
            },
          );
        } catch (e) {
          debugPrint('login audit log failed: $e');
        }
      }
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapAuthError(e.code);
      Get.snackbar(
        'Google Sign-In Failed',
        errorMessage.value,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      errorMessage.value = 'Google Sign-In failed. Please try again.';
      Get.snackbar(
        'Google Sign-In Failed',
        errorMessage.value,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Alias matching spec naming
  Future<void> login(String email, String password) => signIn(email, password);

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      Get.snackbar(
        'Email Sent',
        'Reset email sent. Check your inbox.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Error',
        _mapAuthError(e.code),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    }
  }

  Future<void> signOut() async {
    // Audit log BEFORE we clear auth state so actorId is available.
    try {
      await ActivityLogService.log(
        action: 'logout',
        targetId: uid,
        targetType: 'user',
        targetName: displayName,
        metadata: {
          'platform': kIsWeb ? 'web' : 'mobile',
        },
      );
    } catch (e) {
      debugPrint('logout audit log failed: $e');
    }

    // Best-effort: deactivate FCM token before clearing auth state.
    try {
      // Lazy import to avoid circular controller<->service dependency at startup.
      // ignore: avoid_dynamic_calls
      await _deactivateFcmToken();
    } catch (_) {}

    // Sign out from Google Sign-In
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out error: $e');
    }

    await _auth.signOut();
    currentUser.value = null;
    isProfileLoaded.value = false;
  }

  Future<void> _deactivateFcmToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final tokens = await _firestore
        .collection('fcm_tokens')
        .where('userId', isEqualTo: uid)
        .get();
    for (final doc in tokens.docs) {
      await doc.reference.update({'isActive': false});
    }
  }

  Future<void> logout() => signOut();

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try later.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final updates = <String, dynamic>{};
    if (fullName != null) updates['fullName'] = fullName;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    if (updates.isEmpty) return;
    try {
      await _firestore.collection('users').doc(uid).update(updates);
      await _loadUserData(uid);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  bool get isLeader => currentUser.value?.isLeader ?? false;
  bool get isSupervisor => currentUser.value?.isSupervisor ?? false;
  bool get isSupervisorOrLeader =>
      currentUser.value?.isSupervisorOrLeader ?? false;
  bool get isMember => currentUser.value?.isMember ?? false;

  String get uid => _auth.currentUser?.uid ?? '';
  String get currentUid => uid;
  String get displayName => currentUser.value?.fullName ?? '';
  String get currentName => displayName;
  String get role => currentUser.value?.role ?? 'member';
  String get currentRole => role;
  String get teamId => currentUser.value?.teamId ?? '';
}
