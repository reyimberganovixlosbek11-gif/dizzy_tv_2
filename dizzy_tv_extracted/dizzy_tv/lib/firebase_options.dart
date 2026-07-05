import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web uchun hali sozlanmagan.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS uchun hali sozlanmagan.',
        );
      default:
        throw UnsupportedError(
          'Bu platforma uchun DefaultFirebaseOptions sozlanmagan.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDuVA4Xph9Ant9hc9cAew9muu4VQDunHIo',
    appId: '1:793170387114:android:3f5e5425e72a07744c30d3',
    messagingSenderId: '793170387114',
    projectId: 'isobek-b1c1f',
    storageBucket: 'isobek-b1c1f.firebasestorage.app',
  );
}
