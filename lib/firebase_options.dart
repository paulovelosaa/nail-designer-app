import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

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
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError('Plataforma não suportada');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBKaYS2no7a5v_zqwxtFcUCmd1DotXn1e0",
    authDomain: "nail-designer-app.firebaseapp.com",
    projectId: "nail-designer-app",
    storageBucket: "nail-designer-app.firebasestorage.app",
    messagingSenderId: "130435206637",
    appId: "1:130435206637:web:9bb0faafe84918aad62be4",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyBKaYS2no7a5v_zqwxtFcUCmd1DotXn1e0",
    authDomain: "nail-designer-app.firebaseapp.com",
    projectId: "nail-designer-app",
    storageBucket: "nail-designer-app.firebasestorage.app",
    messagingSenderId: "130435206637",
    appId: "1:130435206637:web:9bb0faafe84918aad62be4",
  );

  static const FirebaseOptions macos = ios;
  static const FirebaseOptions windows = android;
  static const FirebaseOptions linux = android;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBKaYS2no7a5v_zqwxtFcUCmd1DotXn1e0",
    authDomain: "nail-designer-app.firebaseapp.com",
    projectId: "nail-designer-app",
    storageBucket: "nail-designer-app.firebasestorage.app",
    messagingSenderId: "130435206637",
    appId: "1:130435206637:web:9bb0faafe84918aad62be4",
  );
}
