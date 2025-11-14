import 'package:firebase_auth/firebase_auth.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add this import

class AuthGuard {
  static const publicRoutes = [
    '/signIn',
    '/signUp',
    '/resetPwd',
    '/calendar',
    '/invoice',
    '/profile',
    '/formElements',
    '/formLayout',
    '/tables',
    '/contacts',
    '/advancetable',
    '/settings',
    '/alerts',
    '/buttons',
    '/toast',
    '/modal',
    '/basicChart',
    '/forgotPwd',
    // '/assocs'
  ];

  static bool isPublicRoute(String path) {
    return publicRoutes.contains(path);
  }

  static bool isAuthenticated(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return firebaseUser != null && userProvider.user != null;
  }

  static bool canAccess(String path, BuildContext context) {
    return isPublicRoute(path) || isAuthenticated(context);
  }
}
