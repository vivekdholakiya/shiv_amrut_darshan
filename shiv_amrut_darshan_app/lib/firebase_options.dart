import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// DefaultFirebaseOptions configures Firebase for Android and Web.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }



  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBiQIW7KUD1XmNTrluDqnkv88ybyaNkZNY',
    appId: '1:1006401967313:android:5ec2e420a966ce1f55a1f0',
    messagingSenderId: '1006401967313',
    projectId: 'shiv-amrut-darshan',
    storageBucket: 'shiv-amrut-darshan.firebasestorage.app',
  );


}
