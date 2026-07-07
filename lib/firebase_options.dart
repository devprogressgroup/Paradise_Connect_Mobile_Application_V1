

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
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyARKkkCwhqqTeqHUQ8OFloW4e9gDg8WmrY',
    appId: '1:729428932735:android:8bb0a4e0d2f84631a6274a',
    messagingSenderId: '729428932735',
    projectId: 'paradise-connect-mobile-6effd',
    storageBucket: 'paradise-connect-mobile-6effd.firebasestorage.app',
  );
  

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA4zCrddsInlOO8UjNzfr_5bGnYTE63RLs',
    appId: '1:729428932735:ios:c7491da858b2495aa6274a',
    messagingSenderId: '729428932735',
    projectId: 'paradise-connect-mobile-6effd',
    storageBucket: 'paradise-connect-mobile-6effd.firebasestorage.app',
    iosBundleId: 'id.co.progressgroup.connect',
  );
  

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAED1oPCnC4UooAu5E_XhJ6ESi5szeEsdo',
    appId: '1:729428932735:web:baa1b4577aa0ca01a6274a',
    messagingSenderId: '729428932735',
    projectId: 'paradise-connect-mobile-6effd',
    authDomain: 'paradise-connect-mobile-6effd.firebaseapp.com',
    storageBucket: 'paradise-connect-mobile-6effd.firebasestorage.app',
    measurementId: 'G-CSPZP3F9M7',
  );
}
