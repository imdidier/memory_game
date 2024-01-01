import 'package:fluro/fluro.dart';
import 'package:huts_web/core/router/routes_handlers.dart';

class CustomRouter {
  static final FluroRouter fluroRouter = FluroRouter();

  //Main
  static String rootRoute = "/";
  static String signInRoute = "/sign-in";
  static String dashboardRoute = "/dashboard";
  static String activityRoute = "/activity";
  static String profileRoute = "/admin-profile";
  static String requestsRoute = "/requests";
  static String paymentsRoute = "/payments";
  static String adminsRoute = "/admins";
  static String preRegisteredRoute = "/pre-registered";
  static String employees = "/employees";
  static String fares = "/fares";
  static String clients = "/clients";
  static String messages = "/messages";
  static String settings = "/settings";
  static String employeeDetails = "/employee-details/:id";
  static String preRegisteredDetails = "/pre-registered-details/:id";
  static String clientDetails = "/client-details/:id";

  static String getRouteByName() {
    return "";
  }

  static void configureRoutes() {
    fluroRouter.define(
      rootRoute,
      handler: RoutesHandlers.signIn,
      transitionType: TransitionType.fadeIn,
    );
    fluroRouter.define(
      signInRoute,
      handler: RoutesHandlers.signIn,
      transitionType: TransitionType.fadeIn,
    );
    fluroRouter.define(
      dashboardRoute,
      handler: RoutesHandlers.dashboard,
      transitionType: TransitionType.fadeIn,
    );
    fluroRouter.define(
      activityRoute,
      handler: RoutesHandlers.activity,
      transitionType: TransitionType.fadeIn,
    );
    fluroRouter.define(
      profileRoute,
      handler: RoutesHandlers.profile,
      transitionType: TransitionType.fadeIn,
    );
    fluroRouter.define(
      requestsRoute,
      handler: RoutesHandlers.requests,
      transitionType: TransitionType.fadeIn,
    );
    fluroRouter.define(
      paymentsRoute,
      handler: RoutesHandlers.payments,
      transitionType: TransitionType.fadeIn,
    );
    fluroRouter.define(
      preRegisteredRoute,
      handler: RoutesHandlers.preRegistered,
      transitionType: TransitionType.fadeIn,
    );
    fluroRouter.define(
      adminsRoute,
      handler: RoutesHandlers.admins,
      transitionType: TransitionType.fadeIn,
    );
    fluroRouter.define(
      employees,
      handler: RoutesHandlers.employees,
      transitionType: TransitionType.fadeIn,
    );
    fluroRouter.define(
      fares,
      handler: RoutesHandlers.fares,
      transitionType: TransitionType.fadeIn,
    );
    fluroRouter.define(
      clients,
      handler: RoutesHandlers.clients,
      transitionType: TransitionType.fadeIn,
    );
    fluroRouter.define(
      messages,
      handler: RoutesHandlers.messages,
      transitionType: TransitionType.fadeIn,
    );
    fluroRouter.define(
      settings,
      handler: RoutesHandlers.settings,
      transitionType: TransitionType.fadeIn,
    );

    fluroRouter.define(
      employeeDetails,
      handler: RoutesHandlers.employeeDetails,
      transitionType: TransitionType.fadeIn,
    );
    fluroRouter.define(
      preRegisteredDetails,
      handler: RoutesHandlers.preRegisteredDetails,
      transitionType: TransitionType.fadeIn,
    );
    fluroRouter.define(
      clientDetails,
      handler: RoutesHandlers.clientDetails,
      transitionType: TransitionType.fadeIn,
    );
    fluroRouter.notFoundHandler = RoutesHandlers.noPageFound;
  }
}
