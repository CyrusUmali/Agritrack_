// ignore_for_file: library_prefixes, unused_import

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flareline/auth_guard.dart';
import 'package:flareline/deferred_widget.dart';
import 'package:flareline/pages/auth/forgot_password/forgot_password.dart'
    deferred as forgotPwd;
import 'package:flareline/pages/auth/not_found.dart';
import 'package:flareline/pages/auth/sign_in/sign_in_page.dart';
import 'package:flareline/pages/farms/farms_page.dart';
import 'package:flareline/services/roleguard.dart';
import 'package:flareline/splash_screen.dart';
import 'package:flutter/material.dart';

import 'package:flareline/pages/contactus/contact_us.dart'
    deferred as contactUs;
import 'package:flareline/pages/auth/sign_in/sign_in_page.dart'
    deferred as signIn;
import 'package:flareline/pages/auth/sign_up/sign_up_page.dart'
    deferred as signUp;
import 'package:flareline/pages/dashboard/dashboard_page.dart';
import 'package:flareline/pages/resetpwd/reset_pwd_page.dart'
    deferred as resetPwd;
import 'package:flareline/pages/setting/settings_page.dart'
    deferred as settings;

import 'package:flareline/pages/map/Map.dart'
    deferred as mapPage; // Import your new page

import 'package:flareline/pages/farms/farms_page.dart'
    deferred as farmsPage; // Import your new page

import 'package:flareline/pages/assoc/assoc_page.dart'
    deferred as assocsPage; // Import your new page

import 'package:flareline/pages/users/users_page.dart' deferred as usersPage;
import 'package:flareline/pages/farmers/farmers_page.dart'
    deferred as farmersPage;
import 'package:flareline/pages/products/products_page.dart'
    deferred as productsPage;
import 'package:flareline/pages/sectors/sectors_page.dart'
    deferred as sectorsPage;

import 'package:flareline/pages/recommendation/recommendation_page.dart'
    deferred as recommendationPage;

import 'package:flareline/pages/recommendation/chatbot/chatbot_page.dart'
    deferred as chatbotPage;

import 'package:flareline/pages/reports/report_page.dart'
    deferred as reportsPage;
import 'package:flareline/pages/yields/yields_page.dart' deferred as yieldsPage;

typedef PathWidgetBuilder = Widget Function(BuildContext, String?);
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

// ignore: non_constant_identifier_names
final List<Map<String, Object>> MAIN_PAGES = [
  {'routerPath': '/', 'widget': const Dashboard()},
  {
    'routerPath': '/contactus',
    'widget':
        DeferredWidget(contactUs.loadLibrary, () => contactUs.ContactUsPage())
  },
  {
    'routerPath': '/signIn',
    'widget': DeferredWidget(signIn.loadLibrary, () => signIn.SignInWidget())
  },
  {
    'routerPath': '/signUp',
    'widget': DeferredWidget(signUp.loadLibrary, () => signUp.SignUpWidget())
  },
  {
    'routerPath': '/forgotPwd',
    'widget': DeferredWidget(
        forgotPwd.loadLibrary, () => forgotPwd.ForgotPasswordWidget()),
  },
  {
    'routerPath': '/map',
    'widget': DeferredWidget(mapPage.loadLibrary,
        () => mapPage.Map(routeObserver: routeObserver) // Pass observer here
        ), // Add new page
  },
  {
    'routerPath': '/farms',
    'widget': DeferredWidget(
        farmsPage.loadLibrary, () => farmsPage.FarmsPage()), // Add new page
  },
  {
    'routerPath': '/usersPage',
    'widget': DeferredWidget(
        usersPage.loadLibrary, () => usersPage.UsersPage()), // Add new page
  },
  {
    'routerPath': '/farmers',
    'widget': DeferredWidget(farmersPage.loadLibrary,
        () => farmersPage.FarmersPage()), // Add new page
  },
  {
    'routerPath': '/products',
    'widget': DeferredWidget(productsPage.loadLibrary,
        () => productsPage.ProductsPage()), // Add new page
  },
  {
    'routerPath': '/sectors',
    'widget': DeferredWidget(sectorsPage.loadLibrary,
        () => sectorsPage.SectorsPage()), // Add new page
  },
  {
    'routerPath': '/recommendation',
    'widget': DeferredWidget(recommendationPage.loadLibrary,
        () => recommendationPage.RecommendationPage()), // Add new page
  },
  {
    'routerPath': '/chatbot',
    'widget': DeferredWidget(chatbotPage.loadLibrary,
        () => chatbotPage.ChatbotPage()), // Add new page
  },
  {
    'routerPath': '/reports',
    'widget': DeferredWidget(reportsPage.loadLibrary,
        () => reportsPage.ReportsPage()), // Add new page
  },
  {
    'routerPath': '/assocs',
    'widget': DeferredWidget(
        assocsPage.loadLibrary, () => assocsPage.AssocsPage()), // Add new page
  },
  {
    'routerPath': '/yields',
    'widget': DeferredWidget(
        yieldsPage.loadLibrary, () => yieldsPage.YieldsPage()), // Add new page
  },
];

class RouteConfiguration {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'Rex');

  static BuildContext? get navigatorContext =>
      navigatorKey.currentState?.context;

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final path = settings.name!;
    final context = navigatorContext!;

    // First handle public routes
    if (AuthGuard.isPublicRoute(path)) {
      final map = MAIN_PAGES.firstWhere(
        (element) => element['routerPath'] == path,
        orElse: () => {'widget': const NotFoundPage()},
      );
      final targetPage = map['widget'] as Widget;
      return NoAnimationMaterialPageRoute<void>(
        builder: (context) => targetPage,
        settings: settings,
      );
    }

    // Then check authentication for protected routes
    if (!AuthGuard.isAuthenticated(context)) {
      return NoAnimationMaterialPageRoute<void>(
        builder: (context) => SignInWidget(),
        settings: const RouteSettings(name: '/signIn'),
      );
    }

    // Then check role access
    if (!RoleGuard.canAccess(path, context)) {
      return NoAnimationMaterialPageRoute<void>(
        builder: (context) => const NotFoundPage(),
        settings: settings,
      );
    }

    // Handle protected routes
    final map = MAIN_PAGES.firstWhere(
      (element) => element['routerPath'] == path,
      orElse: () => {'widget': const NotFoundPage()},
    );
    final targetPage = map['widget'] as Widget;
    return NoAnimationMaterialPageRoute<void>(
      builder: (context) => targetPage,
      settings: settings,
    );
  }
}

class NoAnimationMaterialPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationMaterialPageRoute({
    required super.builder,
    super.settings,
  });

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
