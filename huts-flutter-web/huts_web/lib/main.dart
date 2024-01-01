import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huts_web/core/firebase_config/firebase_services.dart';
import 'package:huts_web/core/router/router.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_scroll_behavior.dart';
import 'package:huts_web/core/utils/ui/layout/main_layout.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_date_selector.dart';
import 'package:huts_web/features/activity/display/providers/activity_provider.dart';
import 'package:huts_web/features/auth/display/providers/auth_provider.dart';
import 'package:huts_web/features/auth/display/screens/sign_in_screen.dart';
import 'package:huts_web/features/admins/display/providers/admin_provider.dart';
import 'package:huts_web/features/clients/display/provider/clients_provider.dart';
import 'package:huts_web/features/employees/display/provider/employees_provider.dart';
import 'package:huts_web/features/fares/display/provider/fares_provider.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:huts_web/features/general_info/display/screens/splash_screen.dart';
import 'package:huts_web/features/messages/display/provider/messages_provider.dart';
import 'package:huts_web/features/payments/display/providers/payments_provider.dart';
import 'package:huts_web/features/pre_registered/display/provider/pre_registered_provider.dart';
import 'package:huts_web/features/profile_info/domain/display/providers/map_provider.dart';
import 'package:huts_web/features/profile_info/domain/display/providers/profile_provider.dart';
import 'package:huts_web/features/requests/display/providers/create_event_provider.dart';
import 'package:huts_web/features/requests/display/providers/get_requests_provider.dart';
import 'package:huts_web/features/settings/display/providers/settings_provider.dart';
import 'package:huts_web/features/statistics/display/providers/dashboard_provider.dart';
import 'package:provider/provider.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/navigation_service.dart';
import 'core/utils/ui/providers/sidebar_provider.dart';

//import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/clients/display/provider/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
  );
  CustomRouter.configureRoutes();
  await FirebaseServices.init();
  //initializeDateFormatting().then((_) => runApp(const AppState()));
  runApp(const AppState());
}

class AppState extends StatelessWidget {
  const AppState({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => GeneralInfoProvider(),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (BuildContext contextFrom) => AuthProvider(contextFrom),
        ),
        ChangeNotifierProvider(lazy: false, create: (_) => SidebarProvider()),
        ChangeNotifierProvider(lazy: false, create: (_) => ProfileProvider()),
        ChangeNotifierProvider(lazy: false, create: (_) => DashboardProvider()),
        ChangeNotifierProvider(lazy: false, create: (_) => MapProvider()),
        ChangeNotifierProvider(
            lazy: false, create: (_) => GetRequestsProvider()),
        ChangeNotifierProvider(lazy: false, create: (_) => PaymentsProvider()),
        ChangeNotifierProvider(lazy: false, create: (_) => AdminProvider()),
        ChangeNotifierProvider(
            lazy: false, create: (_) => CreateEventProvider()),
        ChangeNotifierProvider(lazy: false, create: (_) => MessagesProvider()),
        ChangeNotifierProvider(lazy: false, create: (_) => ClientsProvider()),
        ChangeNotifierProvider(lazy: false, create: (_) => EmployeesProvider()),
        ChangeNotifierProvider(lazy: false, create: (_) => FaresProvider()),
        ChangeNotifierProvider(lazy: false, create: (_) => UsersProvider()),

        ChangeNotifierProvider(
            lazy: false, create: (_) => PreRegisteredProvider()),
        //CustomDateSelectorProvider//
        ChangeNotifierProvider(lazy: false, create: (_) => SelectorProvider()),
        ChangeNotifierProvider(lazy: false, create: (_) => ActivityProvider()),
        ChangeNotifierProvider(lazy: false, create: (_) => SettingsProvider()),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late GeneralInfoProvider generalInfoProvider;
  @override
  void initState() {
    generalInfoProvider =
        Provider.of<GeneralInfoProvider>(context, listen: false);
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeMetrics() {
    generalInfoProvider.updateScreenSize(
      WidgetsBinding.instance.window.physicalSize,
    );
    super.didChangeMetrics();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: CustomScrollBehavior(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
      ],
      debugShowCheckedModeBanner: false,
      title: 'Huts Web',
      initialRoute: "/",
      onGenerateRoute: CustomRouter.fluroRouter.generator,
      navigatorKey: NavigationService.navigationKey,
      scaffoldMessengerKey: LocalNotificationService.localNotificationKey,
      theme: ThemeData(
        primaryColor: UiVariables.primaryColor,
        scaffoldBackgroundColor: Colors.black,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      builder: (BuildContext builderContext, Widget? child) {
        generalInfoProvider.getScreenSize(context: builderContext);
        final AuthProvider authProvider = Provider.of<AuthProvider>(context);
        return Overlay(
          initialEntries: [
            OverlayEntry(builder: (BuildContext ctx) {
              if (authProvider.authStatus == AuthStatus.checking) {
                return const SplashScreen();
              }
              if (authProvider.authStatus == AuthStatus.authenticated) {
                return MainLayout(
                  child: child!,
                );
              }
              return const SignInScreen();
            })
          ],
        );
      },
    );
  }
}
