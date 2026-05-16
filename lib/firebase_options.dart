import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBFWm20LDY-Wp6vmFHLzZi9nW_q9nvy6fY',
    authDomain: 'taheri-committee-app.firebaseapp.com',
    projectId: 'taheri-committee-app',
    storageBucket: 'taheri-committee-app.firebasestorage.app',
    messagingSenderId: '919937026676',
    appId: '1:919937026676:web:2c5cb3e06a34d2f5ad1f21',
    measurementId: 'G-V5Y00Q4H5N',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBFWm20LDY-Wp6vmFHLzZi9nW_q9nvy6fY',
    authDomain: 'taheri-committee-app.firebaseapp.com',
    projectId: 'taheri-committee-app',
    storageBucket: 'taheri-committee-app.firebasestorage.app',
    messagingSenderId: '919937026676',
    appId: '1:919937026676:android:taheri_committee_app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBFWm20LDY-Wp6vmFHLzZi9nW_q9nvy6fY',
    authDomain: 'taheri-committee-app.firebaseapp.com',
    projectId: 'taheri-committee-app',
    storageBucket: 'taheri-committee-app.firebasestorage.app',
    messagingSenderId: '919937026676',
    appId: '1:919937026676:ios:taheri_committee_app',
    iosBundleId: 'com.taheri.committeeApp',
  );
}
