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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAnL9woWzGfsbUMQpw53xpEHcqP28daFJk',
    appId: '1:870067420485:web:22cc31e24f17e3da02d22c',
    messagingSenderId: '870067420485',
    projectId: 'funance-cef1b',
    authDomain: 'funance-cef1b.firebaseapp.com',
    storageBucket: 'funance-cef1b.firebasestorage.app',
    measurementId: 'G-XXXXXXXXXX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB7-Y1oYV7BXImAL-16zKW34t4Q_DbrWl8',
    appId: '1:870067420485:android:dd117619a51bdb3802d22c',
    messagingSenderId: '870067420485',
    projectId: 'funance-cef1b',
    storageBucket: 'funance-cef1b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAnL9woWzGfsbUMQpw53xpEHcqP28daFJk',
    appId: '1:870067420485:ios:8b13e08dd2c198d902d22c',
    messagingSenderId: '870067420485',
    projectId: 'funance-cef1b',
    storageBucket: 'funance-cef1b.firebasestorage.app',
    iosBundleId: 'br.com.funance',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAnL9woWzGfsbUMQpw53xpEHcqP28daFJk',
    appId: '1:870067420485:ios:8b13e08dd2c198d902d22c', // Frequentemente o mesmo do iOS se não houver um específico
    messagingSenderId: '870067420485',
    projectId: 'funance-cef1b',
    storageBucket: 'funance-cef1b.firebasestorage.app',
    iosBundleId: 'br.com.funance',
  );
}
