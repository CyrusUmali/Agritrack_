import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class SyncService {
  static Future<Map<String, dynamic>?> getGoogleUserIsolated() async {
    try {
      if (kIsWeb) {
        return await _isolatedWebSignIn();
      } else {
        return await _isolatedMobileSignIn();
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _isolatedWebSignIn() async {
    // Use Google Sign-In Web directly without Firebase
    final googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
       forceCodeForRefreshToken: true, // Force refresh token
      // Add your Google OAuth client ID here
      // clientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
    );
 
    try {
      await googleSignIn.signOut(); // Clear any previous session
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final auth = await googleUser.authentication;

      return {
        'name': googleUser.displayName ?? '',
        'email': googleUser.email,
        'idToken': auth.idToken ?? '',
        'accessToken': auth.accessToken ?? '',
        'photoUrl': googleUser.photoUrl,
      };
    } finally {
      await googleSignIn.signOut();
    }
  }

  static Future<Map<String, dynamic>?> _isolatedMobileSignIn() async {
    final googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
       forceCodeForRefreshToken: true, // Force refresh token
      signInOption: SignInOption.standard,
    );

    try {
      await googleSignIn.signOut(); // Clear any previous session
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final auth = await googleUser.authentication;

      return {
        'name': googleUser.displayName ?? '',
        'email': googleUser.email,
        'idToken': auth.idToken ?? '',
        'accessToken': auth.accessToken ?? '',
        'photoUrl': googleUser.photoUrl,
      };
    } finally {
      await googleSignIn.signOut();
    }
  }
}