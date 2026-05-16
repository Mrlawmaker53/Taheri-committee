import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';

// VAPID public key from Firebase Console → Project Settings → Cloud
// Messaging → Web configuration → Web Push certificates.
const String _kVapidKey =
    'BGYc6unqLPgFq3YRPQkf2i_uz8wNbFWB8cwt9serDGAc-d9FLoEFYe8KcNecvZrvSbEOtIpbpzYcZASx2To-g8g';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: web shows the notification via the service worker; native shows it
  // via flutter_local_notifications channel registered in init().
  // Persisting in-app notification doc happens server-side via Cloud Functions.
}

/// Centralised Firebase Cloud Messaging glue.
///
/// `init()` is invoked unconditionally at app startup (registers handlers and
/// the Android notification channel). `initForUser()` is invoked after a user
/// authenticates — it requests permission, fetches the token and persists it
/// to `fcm_tokens/{tokenId}` so Cloud Functions can target this device.
class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static FlutterLocalNotificationsPlugin? _localNotifs;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'taheri_high_importance',
    'Taheri Committee Notifications',
    description: 'Important notifications from Taheri Committee',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
  );

  static bool _initialised = false;
  static bool _userInitialised = false;

  // ───────────────────────────────────────────────────────────────────────
  // Startup-time init (no auth required)
  // ───────────────────────────────────────────────────────────────────────
  static Future<void> init(FlutterLocalNotificationsPlugin localNotifs) async {
    if (_initialised) return;
    _initialised = true;
    _localNotifs = localNotifs;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Android channel
    if (!kIsWeb) {
      try {
        await localNotifs
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_androidChannel);
      } catch (e) {
        debugPrint('FCM android channel error: $e');
      }
    }

    // Foreground messages — show in-app banner + flutter_local_notifications.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // User tapped a notification while app was in background.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // App opened from terminated state via notification tap.
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) _handleNotificationTap(initialMessage);

    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // Per-user init: call after sign-in.
  // ───────────────────────────────────────────────────────────────────────
  static Future<void> initForUser() async {
    if (_userInitialised) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    AuthorizationStatus authStatus;
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      authStatus = settings.authorizationStatus;
      debugPrint('FCM permission: $authStatus');
    } catch (e) {
      debugPrint('FCM requestPermission error (non-fatal): $e');
      // For web, continue with default status
      if (!kIsWeb) return;
      authStatus = AuthorizationStatus.notDetermined;
      debugPrint('FCM permission: $authStatus (web default)');
    }

    // On web, browsers silently reject requestPermission() when it is called
    // outside a user-gesture handler. In that case authorizationStatus is
    // "notDetermined" or "denied" even though the user hasn't seen a dialog.
    // We intentionally do NOT set _userInitialised = true here so that the
    // login_screen can retry the call from within the OTP button press (a real
    // user gesture), which will trigger the browser permission popup.
    if (kIsWeb &&
        authStatus != AuthorizationStatus.authorized &&
        authStatus != AuthorizationStatus.provisional) {
      debugPrint(
          'ℹ️ FCM: web permission not granted — will retry from user gesture');
      // Don't return - try to get token anyway for web
    }

    String? token;
    try {
      if (kIsWeb) {
        token = await _fcm.getToken(vapidKey: _kVapidKey);
      } else {
        token = await _fcm.getToken();
      }
    } catch (e) {
      debugPrint('FCM getToken error: $e');
      // For web, this might be a service worker issue - try again after delay
      if (kIsWeb) {
        debugPrint(
            '🔄 Retrying FCM token for web after service worker issue...');
        await Future.delayed(const Duration(seconds: 2));
        try {
          token = await _fcm.getToken(vapidKey: _kVapidKey);
        } catch (retryError) {
          debugPrint('FCM retry failed: $retryError');
          return;
        }
      } else {
        return;
      }
    }

    if (token != null && token.isNotEmpty) {
      await _saveToken(token);
      debugPrint('✅ FCM token saved (${token.substring(0, 20)}…)');
    } else {
      debugPrint('⚠️ FCM token is null or empty');
    }

    _fcm.onTokenRefresh.listen(_saveToken);
    _userInitialised = true;
  }

  /// Reset internal flag on logout so next login re-runs initForUser().
  static void resetUserState() {
    _userInitialised = false;
  }

  // ───────────────────────────────────────────────────────────────────────
  // Token persistence
  // ───────────────────────────────────────────────────────────────────────
  static Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final platform = _platformLabel();
    try {
      final existing = await _db
          .collection('fcm_tokens')
          .where('userId', isEqualTo: uid)
          .where('token', isEqualTo: token)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) {
        final ref = _db.collection('fcm_tokens').doc();
        await ref.set({
          'tokenId': ref.id,
          'userId': uid,
          'token': token,
          'platform': platform,
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
      } else {
        await existing.docs.first.reference.update({
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'platform': platform,
        });
      }
    } catch (e) {
      debugPrint('FCM token persist error: $e');
    }
  }

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'unknown';
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // Message handling
  // ───────────────────────────────────────────────────────────────────────
  static void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;
    final title = notification?.title ?? data['title'] ?? 'Notification';
    final body = notification?.body ?? data['body'] ?? '';
    final requiresResponse = data['requiresResponse'] == 'true';

    // Pick a tint that matches the notification type so users can
    // distinguish auth audits / announcements / events at a glance.
    final type = (data['type'] ?? '').toString();
    Color bg;
    Color fg;
    switch (type) {
      case 'auth_audit':
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade900;
        break;
      case 'announcement':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        break;
      case 'event_rsvp':
        bg = Colors.green.shade50;
        fg = Colors.green.shade900;
        break;
      default:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade900;
    }

    // 1. In-app banner (GetX snackbar) — clickable.
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 6),
      backgroundColor: bg,
      colorText: fg,
      borderRadius: 12,
      margin: const EdgeInsets.all(12),
      mainButton: TextButton(
        onPressed: () {
          if (Get.isSnackbarOpen) Get.back();
          _routeFromNotification(data);
        },
        child: Text(
          requiresResponse ? 'Respond' : 'View',
          style: TextStyle(color: fg, fontWeight: FontWeight.w600),
        ),
      ),
    );

    // 2. Native heads-up notification on Android (web is handled by SW).
    if (!kIsWeb && _localNotifs != null && notification != null) {
      _localNotifs!.show(
        notification.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            ticker: title,
          ),
        ),
      );
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    _routeFromNotification(message.data);
  }

  static void _routeFromNotification(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString();
    switch (type) {
      case 'event_rsvp':
        Get.toNamed(AppRoutes.eventDetail,
            arguments: {'eventId': data['eventId']});
        break;
      case 'announcement':
        Get.toNamed(AppRoutes.announcements);
        break;
      case 'contribution':
        Get.toNamed(AppRoutes.myContributions);
        break;
      case 'transfer':
        Get.toNamed(AppRoutes.raiseTransfer);
        break;
      case 'auth_audit':
        Get.toNamed(AppRoutes.activityLog);
        break;
      default:
        Get.toNamed(AppRoutes.notifications);
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // Legacy helpers (kept for backwards compatibility)
  // ───────────────────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    if (kIsWeb) return _fcm.getToken(vapidKey: _kVapidKey);
    return _fcm.getToken();
  }

  static Future<void> subscribeToTopic(String topic) =>
      _fcm.subscribeToTopic(topic);

  static Future<void> unsubscribeFromTopic(String topic) =>
      _fcm.unsubscribeFromTopic(topic);
}
