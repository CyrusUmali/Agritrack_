import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static Future<Map<String, dynamic>?> getGoogleUserIsolated() async {
    try {
      if (kIsWeb) {
        return await _isolatedWebSignIn();
      } else {
        return await _isolatedMobileSignIn();
      }
    } catch (e) {
      debugPrint('Isolated Google Sign-In error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _isolatedWebSignIn() async {
    // Get options from default app
    final defaultApp = Firebase.app();
    final options = defaultApp.options;

    // Create isolated instance
    final isolatedApp = await Firebase.initializeApp(
      name: 'googleSignInTemp_${DateTime.now().millisecondsSinceEpoch}',
      options: options,
    );

    final isolatedAuth = FirebaseAuth.instanceFor(
      app: isolatedApp,
      persistence: Persistence.NONE, // Disable persistence
    );

    try {
      // Force account selection by setting prompt parameter
      final googleProvider = GoogleAuthProvider()
        ..setCustomParameters({
          'prompt': 'select_account', // This forces account selection
        });

      final result = await isolatedAuth.signInWithPopup(googleProvider);
      final user = result.user;
      if (user == null) return null;

      final token = await user.getIdToken();

      return {
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'idToken': token ?? '',
        'photoUrl': user.photoURL,
      };
    } finally {
      // Critical cleanup
      await isolatedAuth.signOut();
      await isolatedApp.delete();
    }
  }

  static Future<Map<String, dynamic>?> _isolatedMobileSignIn() async {
    final googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      signInOption: SignInOption.standard,
    );

    try {
      // First ensure any previous sign-in is cleared
      await googleSignIn.signOut();

      // Then start a fresh sign-in
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final auth = await googleUser.authentication;

      return {
        'name': googleUser.displayName ?? '',
        'email': googleUser.email,
        'idToken': auth.idToken ?? '',
        'photoUrl': googleUser.photoUrl,
      };
    } finally {
      await googleSignIn.signOut();
    }
  }
}
