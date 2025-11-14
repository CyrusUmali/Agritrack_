import 'package:flareline/core/theme/global_theme.dart';
import 'package:flareline/pages/assoc/assoc_bloc/assocs_bloc.dart';
import 'package:flareline/pages/dashboard/yield_service.dart';
import 'package:flareline/pages/farmers/farmer/farmer_bloc.dart';
import 'package:flareline/pages/farms/farm_bloc/farm_bloc.dart';
import 'package:flareline/pages/products/product/product_bloc.dart';
import 'package:flareline/pages/test/map_widget/farm_service.dart';
import 'package:flareline/pages/users/user_bloc/user_bloc.dart';
import 'package:flareline/pages/yields/yield_bloc/yield_bloc.dart';
import 'package:flareline/providers/language_provider.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline/repositories/assocs_repository.dart';
import 'package:flareline/repositories/farm_repository.dart';
import 'package:flareline/repositories/farmer_repository.dart';
import 'package:flareline/repositories/product_repository.dart';
import 'package:flareline/repositories/user_repository.dart';
import 'package:flareline/repositories/yield_repository.dart';
import 'package:flareline/services/api_service.dart';
import 'package:flareline/services/report_service.dart';
import 'package:flareline_uikit/service/localization_provider.dart';
import 'package:flareline/routes.dart';
import 'package:flareline_uikit/service/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flareline/flutter_gen/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flareline/pages/sectors/sector_service.dart';
import 'package:flareline_uikit/service/sidebar_provider.dart';
import 'package:flareline_uikit/service/year_picker_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FullScreen.ensureInitialized();
  await GetStorage.init();
  // Initialize Firebase only once here
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize API service and wake up the server (added here)
  final apiService = ApiService();
  await apiService.wakeUpServer(); // Add this method to ApiService (see below)

  if (GetPlatform.isDesktop && !GetPlatform.isWeb) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1080, 720),
      minimumSize: Size(480, 360),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Determine initial route based on auth state
  final initialRoute = await _getInitialRoute();

  runApp(MyApp(initialRoute: initialRoute));
}

Future<String> _getInitialRoute() async {
  // Removed duplicate Firebase initialization here
  final user = FirebaseAuth.instance.currentUser;
  return user != null ? '/' : '/signIn';
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    final productRepository = ProductRepository(apiService: apiService);
    final farmerRepository = FarmerRepository(apiService: apiService);
    final yieldRepository = YieldRepository(apiService: apiService);
    final farmRepository = FarmRepository(apiService: apiService);
    final userRepository = UserRepository(apiService: apiService);
    final assocsRepository = AssociationRepository(apiService: apiService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => SidebarProvider()),
        ChangeNotifierProvider(create: (_) => YearPickerProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(_)),
        ChangeNotifierProvider(create: (_) => LocalizationProvider(_)),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        Provider<ApiService>(create: (_) => apiService),
        Provider<ProductRepository>(create: (_) => productRepository),
        BlocProvider(
          create: (context) => ProductBloc(
            productRepository: context.read<ProductRepository>(),
          )..add(LoadProducts()),
          lazy: false, // Load immediately
        ),
        Provider<AssociationRepository>(create: (_) => assocsRepository),
        BlocProvider(
          create: (context) => AssocsBloc(
            associationRepository: context.read<AssociationRepository>(),
          )..add(LoadAssocs()),
          lazy: true, // Load immediately
        ),
        Provider<FarmerRepository>(create: (_) => farmerRepository),
        BlocProvider(
          create: (context) => FarmerBloc(
            farmerRepository: context.read<FarmerRepository>(),
          )..add(LoadFarmers()),
          lazy: false, // Load immediately
        ),
        RepositoryProvider(
          create: (context) => SectorService(ApiService()),
        ),
        RepositoryProvider(
          create: (context) => FarmService(ApiService()),
        ),
        RepositoryProvider(
          create: (context) => ReportService(ApiService()),
        ),
        RepositoryProvider(
          create: (context) => YieldService(ApiService()),
        ),
        Provider<YieldRepository>(create: (_) => yieldRepository),
        BlocProvider(
          create: (context) => YieldBloc(
            yieldRepository: context.read<YieldRepository>(),
          )..add(LoadYields()),
          lazy: false, // Load immediately
        ),
        Provider<FarmRepository>(create: (_) => farmRepository),
        BlocProvider(
          create: (context) => FarmBloc(
            farmRepository: context.read<FarmRepository>(),
          )..add(LoadFarms()),
          lazy: false, // Load immediately
        ),
        Provider<UserRepository>(create: (_) => userRepository),
        BlocProvider(
          create: (context) => UserBloc(
            userRepository: context.read<UserRepository>(),
          )..add(LoadUsers()),
          lazy: false, // Load immediately
        ),
      ],
      child: Builder(builder: (context) {
        context.read<LocalizationProvider>().supportedLocales =
            AppLocalizations.supportedLocales;
        final RouteObserver<PageRoute> routeObserver =
            RouteObserver<PageRoute>();

        FirebaseAuth.instance.authStateChanges().listen((User? user) {
          if (user == null) {
            RouteConfiguration.navigatorKey.currentState
                ?.pushReplacementNamed('/signIn');
          }
        });

        return MaterialApp(
          navigatorObservers: [routeObserver],
          navigatorKey: RouteConfiguration.navigatorKey,
          restorationScopeId: 'rootFlareLine',
          title: 'AgriTrack',
          debugShowCheckedModeBanner: false,
          initialRoute: initialRoute,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: context.watch<LocalizationProvider>().locale,
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateRoute: (settings) =>
              RouteConfiguration.onGenerateRoute(settings),
          themeMode: context.watch<ThemeProvider>().isDark
              ? ThemeMode.dark
              : ThemeMode.light,
          theme: GlobalTheme.lightThemeData,
          darkTheme: GlobalTheme.darkThemeData,
          builder: (context, widget) {
            return ToastificationWrapper(
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.noScaling),
                child: widget!,
              ),
            );
          },
        );
      }),
    );
  }
}
