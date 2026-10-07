import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBURgrx5TAPrs_A9mCL8L-XuP2umHK_iw4',
    appId: '1:468792959430:android:ab69419e819cdc2d7f52c7',
    messagingSenderId: '468792959430',
    projectId: 'smart-school-2be4c',
    storageBucket: 'smart-school-2be4c.firebasestorage.app',
  );
}
