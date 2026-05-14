// Generado manualmente a partir del google-services.json del proyecto santatotuma-7ce14.
// Para iOS: agrega GoogleService-Info.plist y completa la sección iosOptions.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw _unsupported('Web');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw _unsupported('iOS — agrega GoogleService-Info.plist');
      default:
        throw _unsupported(defaultTargetPlatform.name);
    }
  }

  static UnsupportedError _unsupported(String plataforma) =>
      UnsupportedError('Firebase no configurado para $plataforma.');

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDO-b5wcIDb78KBd5F09wc7_0a_gcg8MSM',
    appId: '1:100860680950:android:e9c4f338a0ccb7a009ead7',
    messagingSenderId: '100860680950',
    projectId: 'santatotuma-7ce14',
    storageBucket: 'santatotuma-7ce14.firebasestorage.app',
  );
}
