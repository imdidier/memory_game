import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:huts_web/core/router/router.dart';
import 'package:huts_web/features/auth/display/screens/sign_in_screen.dart';
import 'package:huts_web/features/activity/display/screens/activity_screen.dart';
import 'package:huts_web/features/clients/display/screens/client_details.dart';
import 'package:huts_web/features/clients/display/screens/clients_screen.dart';
import 'package:huts_web/features/employees/display/screens/employee_details.dart';
import 'package:huts_web/features/employees/display/screens/employees_screen.dart';
import 'package:huts_web/features/fares/display/screens/fares_screen.dart';
import 'package:huts_web/features/general_info/display/screens/splash_screen.dart';
import 'package:huts_web/features/messages/display/screens/messages_screen.dart';
import 'package:huts_web/features/payments/display/screens/payments_screen.dart';
import 'package:huts_web/features/pre_registered/display/screens/pre_registered_details.dart';
import 'package:huts_web/features/pre_registered/display/screens/pre_registered_screen.dart';
import 'package:huts_web/features/requests/display/screens/requests_screen.dart';
import 'package:huts_web/features/settings/display/screens/settings.dart';
import 'package:huts_web/features/statistics/display/screens/dashboard_screen.dart';
import 'package:provider/provider.dart';

import '../../features/auth/display/providers/auth_provider.dart';
import '../../features/admins/display/screens/admins_screen.dart';
import '../../features/general_info/display/screens/screen_404.dart';
import '../utils/ui/providers/sidebar_provider.dart';

class RoutesHandlers {
  static Handler noPageFound = Handler(handlerFunc: (context, params) {
    Provider.of<SidebarProvider>(context!, listen: false)
        .setCurrentPageUrl("404");
    return const Screen404();
  });
  static Handler splash = Handler(
    handlerFunc: (_, __) => const SplashScreen(),
  );

  static List<Map<String, dynamic>> routesScreens = [
    {
      "route": "/activity",
      "screen": const ActivityScreen(),
    },
    {
      "route": "/admins",
      "screen": const AdminsScreen(),
    },
    {
      "route": "/clients",
      "screen": const ClientsScreen(),
    },
    {
      "route": "/dashboard",
      "screen": const DashboardScreen(),
    },
    {
      "route": "/employees",
      "screen": const EmployeesScreen(),
    },
    {
      "route": "/fares",
      "screen": const FaresScreen(),
    },
    {
      "route": "/messages",
      "screen": const MessagesScreen(),
    },
    {
      "route": "/payments",
      "screen": const PaymentsScreen(),
    },
    {
      "route": "/pre-registered",
      "screen": const PreRegisteredScreen(),
    },
    {
      "route": "/requests",
      "screen": const RequestsScreen(),
    },
    {
      "route": "/settings",
      "screen": const SettingsScreen(),
    },
  ];

  static Handler signIn = Handler(handlerFunc: (BuildContext? context, __) {
    SidebarProvider sidebarProvider = context!.read<SidebarProvider>();
    final AuthProvider authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.authStatus == AuthStatus.authenticated) {
      AuthProvider authProvider = context.read<AuthProvider>();

      String userType = authProvider.webUser.accountInfo.type;

      String userSubtype = authProvider.webUser.accountInfo.subtype;

      Map<String, dynamic> webRoutes = authProvider.temporalOtherInfo.webRoutes;

      Map<String, dynamic> sortedWebRoutes = Map.fromEntries(
        webRoutes.entries.toList()
          ..sort(
            (e1, e2) => e1.value["info"]["position"]
                .compareTo(e2.value["info"]["position"]),
          ),
      );

      Map<String, dynamic> routesScreen = {};

      for (String key in sortedWebRoutes.keys) {
        Map<String, dynamic> routeData = sortedWebRoutes[key];

        if (routeData["info"]["text"] == "Perfil") continue;
        if (!routeData["visibility"][userType]["enabled"]) continue;
        if (!routeData["visibility"][userType][userSubtype]) continue;

        routesScreen = routesScreens.firstWhere(
          (element) => element["route"] == routeData["info"]["route"],
        );

        break;
      }

      sidebarProvider.setCurrentPageUrl(routesScreen["route"]);
      return routesScreen["screen"];
    }

    sidebarProvider.setCurrentPageUrl(CustomRouter.signInRoute);
    return const SignInScreen();
  });
  static Handler dashboard = Handler(handlerFunc: (BuildContext? ctx, _) {
    Provider.of<SidebarProvider>(ctx!, listen: false)
        .setCurrentPageUrl(CustomRouter.dashboardRoute);

    final AuthProvider authProvider = Provider.of<AuthProvider>(ctx);

    if (authProvider.authStatus == AuthStatus.authenticated) {
      String userType = authProvider.webUser.accountInfo.type;
      String userSubtype = authProvider.webUser.accountInfo.subtype;
      Map<String, dynamic> webRoutes = authProvider.temporalOtherInfo.webRoutes;

      if (!webRoutes["dashboard"]["visibility"][userType]["enabled"]) {
        return const Screen404();
      }

      if (!webRoutes["dashboard"]["visibility"][userType][userSubtype]) {
        return const Screen404();
      }

      return const DashboardScreen();
    }
    return const SignInScreen();
  });

  static Handler activity = Handler(handlerFunc: (BuildContext? context, __) {
    Provider.of<SidebarProvider>(context!, listen: false)
        .setCurrentPageUrl(CustomRouter.activityRoute);

    final AuthProvider authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.authStatus == AuthStatus.authenticated) {
      String userType = authProvider.webUser.accountInfo.type;
      String userSubtype = authProvider.webUser.accountInfo.subtype;
      Map<String, dynamic> webRoutes = authProvider.temporalOtherInfo.webRoutes;

      if (!webRoutes["activity"]["visibility"][userType]["enabled"]) {
        return const Screen404();
      }

      if (!webRoutes["activity"]["visibility"][userType][userSubtype]) {
        return const Screen404();
      }

      return const ActivityScreen();
    }
    return const SignInScreen();
  });

  static Handler profile = Handler(handlerFunc: (BuildContext? context, __) {
    Provider.of<SidebarProvider>(context!, listen: false)
        .setCurrentPageUrl(CustomRouter.profileRoute);

    final AuthProvider authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.authStatus == AuthStatus.authenticated) {
      return const ActivityScreen();
    }
    return const SignInScreen();
  });

  static Handler requests = Handler(handlerFunc: (BuildContext? context, __) {
    Provider.of<SidebarProvider>(context!, listen: false)
        .setCurrentPageUrl(CustomRouter.requestsRoute);

    final AuthProvider authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.authStatus == AuthStatus.authenticated) {
      String userType = authProvider.webUser.accountInfo.type;
      String userSubtype = authProvider.webUser.accountInfo.subtype;
      Map<String, dynamic> webRoutes = authProvider.temporalOtherInfo.webRoutes;

      if (!webRoutes["requests"]["visibility"][userType]["enabled"]) {
        return const Screen404();
      }

      if (!webRoutes["requests"]["visibility"][userType][userSubtype]) {
        return const Screen404();
      }

      return const RequestsScreen();
    }
    return const SignInScreen();
  });

  static Handler payments = Handler(handlerFunc: (BuildContext? context, __) {
    Provider.of<SidebarProvider>(context!, listen: false)
        .setCurrentPageUrl(CustomRouter.paymentsRoute);

    final AuthProvider authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.authStatus == AuthStatus.authenticated) {
      String userType = authProvider.webUser.accountInfo.type;
      String userSubtype = authProvider.webUser.accountInfo.subtype;
      Map<String, dynamic> webRoutes = authProvider.temporalOtherInfo.webRoutes;

      if (!webRoutes["payments"]["visibility"][userType]["enabled"]) {
        return const Screen404();
      }

      if (!webRoutes["payments"]["visibility"][userType][userSubtype]) {
        return const Screen404();
      }

      return const PaymentsScreen();
    }
    return const SignInScreen();
  });

  static Handler admins = Handler(handlerFunc: (BuildContext? context, __) {
    Provider.of<SidebarProvider>(context!, listen: false)
        .setCurrentPageUrl(CustomRouter.adminsRoute);

    final AuthProvider authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.authStatus == AuthStatus.authenticated) {
      String userType = authProvider.webUser.accountInfo.type;
      String userSubtype = authProvider.webUser.accountInfo.subtype;
      Map<String, dynamic> webRoutes = authProvider.temporalOtherInfo.webRoutes;

      if (!webRoutes["admins"]["visibility"][userType]["enabled"]) {
        return const Screen404();
      }

      if (!webRoutes["admins"]["visibility"][userType][userSubtype]) {
        return const Screen404();
      }

      return const AdminsScreen();
    }
    return const SignInScreen();
  });

  static Handler preRegistered =
      Handler(handlerFunc: (BuildContext? context, __) {
    Provider.of<SidebarProvider>(context!, listen: false)
        .setCurrentPageUrl(CustomRouter.preRegisteredRoute);

    final AuthProvider authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.authStatus == AuthStatus.authenticated) {
      String userType = authProvider.webUser.accountInfo.type;
      String userSubtype = authProvider.webUser.accountInfo.subtype;
      Map<String, dynamic> webRoutes = authProvider.temporalOtherInfo.webRoutes;

      if (!webRoutes["pre_registered"]["visibility"][userType]["enabled"]) {
        return const Screen404();
      }

      if (!webRoutes["pre_registered"]["visibility"][userType][userSubtype]) {
        return const Screen404();
      }

      return const PreRegisteredScreen();
    }
    return const SignInScreen();
  });

  static Handler employees = Handler(handlerFunc: (BuildContext? context, __) {
    Provider.of<SidebarProvider>(context!, listen: false)
        .setCurrentPageUrl(CustomRouter.employees);

    final AuthProvider authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.authStatus == AuthStatus.authenticated) {
      String userType = authProvider.webUser.accountInfo.type;
      String userSubtype = authProvider.webUser.accountInfo.subtype;
      Map<String, dynamic> webRoutes = authProvider.temporalOtherInfo.webRoutes;

      if (!webRoutes["employees"]["visibility"][userType]["enabled"]) {
        return const Screen404();
      }

      if (!webRoutes["employees"]["visibility"][userType][userSubtype]) {
        return const Screen404();
      }

      return const EmployeesScreen();
    }
    return const SignInScreen();
  });

  static Handler fares = Handler(handlerFunc: (BuildContext? context, __) {
    Provider.of<SidebarProvider>(context!, listen: false)
        .setCurrentPageUrl(CustomRouter.fares);

    final AuthProvider authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.authStatus == AuthStatus.authenticated) {
      String userType = authProvider.webUser.accountInfo.type;
      String userSubtype = authProvider.webUser.accountInfo.subtype;
      Map<String, dynamic> webRoutes = authProvider.temporalOtherInfo.webRoutes;

      if (!webRoutes["fares"]["visibility"][userType]["enabled"]) {
        return const Screen404();
      }

      if (!webRoutes["fares"]["visibility"][userType][userSubtype]) {
        return const Screen404();
      }

      return const FaresScreen();
    }
    return const SignInScreen();
  });
  static Handler clients = Handler(handlerFunc: (BuildContext? context, __) {
    Provider.of<SidebarProvider>(context!, listen: false)
        .setCurrentPageUrl(CustomRouter.clients);

    final AuthProvider authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.authStatus == AuthStatus.authenticated) {
      String userType = authProvider.webUser.accountInfo.type;
      String userSubtype = authProvider.webUser.accountInfo.subtype;
      Map<String, dynamic> webRoutes = authProvider.temporalOtherInfo.webRoutes;

      if (!webRoutes["clients"]["visibility"][userType]["enabled"]) {
        return const Screen404();
      }

      if (!webRoutes["clients"]["visibility"][userType][userSubtype]) {
        return const Screen404();
      }

      return const ClientsScreen();
    }
    return const SignInScreen();
  });
  static Handler messages = Handler(handlerFunc: (BuildContext? context, __) {
    Provider.of<SidebarProvider>(context!, listen: false)
        .setCurrentPageUrl(CustomRouter.messages);

    final AuthProvider authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.authStatus == AuthStatus.authenticated) {
      String userType = authProvider.webUser.accountInfo.type;
      String userSubtype = authProvider.webUser.accountInfo.subtype;
      Map<String, dynamic> webRoutes = authProvider.temporalOtherInfo.webRoutes;

      if (!webRoutes["messages"]["visibility"][userType]["enabled"]) {
        return const Screen404();
      }

      if (!webRoutes["messages"]["visibility"][userType][userSubtype]) {
        return const Screen404();
      }

      return const MessagesScreen();
    }
    return const SignInScreen();
  });

  static Handler settings = Handler(handlerFunc: (BuildContext? context, __) {
    Provider.of<SidebarProvider>(context!, listen: false)
        .setCurrentPageUrl(CustomRouter.settings);

    final AuthProvider authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.authStatus == AuthStatus.authenticated) {
      String userType = authProvider.webUser.accountInfo.type;
      String userSubtype = authProvider.webUser.accountInfo.subtype;
      Map<String, dynamic> webRoutes = authProvider.temporalOtherInfo.webRoutes;

      if (!webRoutes["settings"]["visibility"][userType]["enabled"]) {
        return const Screen404();
      }

      if (!webRoutes["settings"]["visibility"][userType][userSubtype]) {
        return const Screen404();
      }

      return const SettingsScreen();
    }
    return const SignInScreen();
  });

  static Handler employeeDetails = Handler(
    handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
      final AuthProvider authProvider = context!.read<AuthProvider>();
      final SidebarProvider sidebarProvider = context.read<SidebarProvider>();

      if (authProvider.authStatus != AuthStatus.authenticated) {
        sidebarProvider.setCurrentPageUrl(CustomRouter.signInRoute);
        return const SignInScreen();
      }
      sidebarProvider.setCurrentPageUrl(CustomRouter.employeeDetails);
      return EmployeeDetailsScreen(employeeId: params["id"]![0]);
    },
  );

  static Handler preRegisteredDetails = Handler(
    handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
      final AuthProvider authProvider = context!.read<AuthProvider>();
      final SidebarProvider sidebarProvider = context.read<SidebarProvider>();

      if (authProvider.authStatus == AuthStatus.authenticated) {
        String userType = authProvider.webUser.accountInfo.type;

        if (userType == "client") {
          return const Screen404();
        }

        sidebarProvider.setCurrentPageUrl(CustomRouter.preRegisteredDetails);
        return PreRegisteredDeteailsScreen(employeeId: params["id"]![0]);
      }

      sidebarProvider.setCurrentPageUrl(CustomRouter.signInRoute);
      return const SignInScreen();
    },
  );

  static Handler clientDetails = Handler(
    handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
      final AuthProvider authProvider = context!.read<AuthProvider>();
      final SidebarProvider sidebarProvider = context.read<SidebarProvider>();

      if (authProvider.authStatus == AuthStatus.authenticated) {
        String userType = authProvider.webUser.accountInfo.type;
        if (userType == "client") {
          return const Screen404();
        }

        sidebarProvider.setCurrentPageUrl(CustomRouter.clientDetails);
        return ClientDetailsScreen(clientId: params["id"]![0]);
      }

      sidebarProvider.setCurrentPageUrl(CustomRouter.signInRoute);
      return const SignInScreen();
    },
  );
}
