import 'package:firebase_auth/firebase_auth.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline/routes.dart';
import 'package:flutter/material.dart'; 
import 'package:flareline/pages/auth/sign_in/sign_in_page.dart';
import 'package:provider/provider.dart'; 



class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.expand();
        }

        // If Firebase has no user, show SignIn
        if (!snapshot.hasData) return   SignInWidget();

        // If Firebase user exists but UserProvider not ready, show blank / spinner
        if (!userProvider.isReady) return const SizedBox.expand();

        // Fully signed in → show app
        return const AppShell();
      },
    );
  }
}



class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: RouteConfiguration.onGenerateRoute,
    );
  }
}