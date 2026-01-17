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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB38FTxat6fTjTN6giHFVKWOCtphJNdXZQ',
    appId: '1:927720982704:web:YOUR_WEB_APP_ID', // REQUESTED FROM USER
    messagingSenderId: '927720982704',
    projectId: 'qari-app-a8840',
    authDomain: 'qari-app-a8840.firebaseapp.com',
    storageBucket: 'qari-app-a8840.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB38FTxat6fTjTN6giHFVKWOCtphJNdXZQ',
    appId: '1:927720982704:android:048c8d1dc94452cac15375',
    messagingSenderId: '927720982704',
    projectId: 'qari-app-a8840',
    storageBucket: 'qari-app-a8840.firebasestorage.app',
  );
}
