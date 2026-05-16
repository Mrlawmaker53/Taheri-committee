import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'core/controllers/auth_controller.dart';
import 'core/controllers/theme_controller.dart';
import 'core/controllers/connectivity_controller.dart';
import 'core/controllers/notification_controller.dart';
import 'core/services/hive_service.dart';
import 'core/services/fcm_service.dart';
import 'core/widgets/app_shell.dart';
import 'core/routes/app_routes.dart';
import 'features/splash/splash_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase connected');

    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      debugPrint('Firestore settings error: $e');
    }
  } catch (e) {
    debugPrint('❌ Firebase init error: $e');
  }

  try {
    await Hive.initFlutter();
    await HiveService.init();
    debugPrint('✅ Hive initialized');
  } catch (e) {
    debugPrint('❌ Hive init error: $e');
  }

  // Initialize FCM (web supported via service worker; native via FCMService).
  try {
    if (!kIsWeb) {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );
    }
    // FCMService.init() registers handlers + Android channel. Token fetch
    // and persistence happens later in initForUser() once the user is authed.
    await FCMService.init(flutterLocalNotificationsPlugin);
  } catch (e) {
    debugPrint('FCM/local notif init error: $e');
  }

  // Register controllers BEFORE runApp so first frame has them ready
  Get.put(ThemeController(), permanent: true);
  Get.put(ConnectivityController(), permanent: true);
  final auth = Get.put(AuthController(), permanent: true);
  Get.put(NotificationController(), permanent: true);

  // Once a user logs in (auth state stabilises), persist the FCM token.
  // On logout, deactivate the user's tokens.
  ever(auth.isLoggedIn, (bool loggedIn) async {
    if (loggedIn) {
      try {
        await FCMService.initForUser();
      } catch (e) {
        debugPrint('FCM initForUser error: $e');
      }
    } else {
      FCMService.resetUserState();
    }
  });

  runApp(const TaheriCommitteeApp());
}

class TaheriCommitteeApp extends StatelessWidget {
  const TaheriCommitteeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<ThemeController>(
      builder: (ctrl) => GetMaterialApp(
        title: 'Taheri Committee',
        theme: ctrl.lightTheme,
        darkTheme: ctrl.darkTheme,
        themeMode: ctrl.themeMode.value,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        unknownRoute: GetPage(name: '/404', page: () => const AppShell()),
        getPages: AppRoutes.pages,
        defaultTransition: Transition.cupertino,
      ),
    );
  }
}
