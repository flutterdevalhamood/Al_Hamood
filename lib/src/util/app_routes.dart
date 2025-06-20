import 'package:flutter/material.dart';
import 'package:sample/src/screens/change_password_screen.dart';
import 'package:sample/src/screens/tyreReplacement/tyre_replacement_data_screen.dart';
import 'package:sample/src/screens/tyreReplacement/tyre_replacement_list_screen.dart';

import '../constants/string_constants.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';

class Screenroutes {
  static final RouteObserver<PageRoute> routeobserver =
      RouteObserver<PageRoute>();

  static const String login = "login";
  static const String dashboard = "DashBoard";

  static const String changePassword = "changePassword";
  static const String userUpdateScreen = "userUpdateScreen";
  static const String profileUpdateScreen = "profileUpdateScreen";

  static const String tyreReplacementListScreen = "tyreReplacementListScreen";
  static const String tyreReplacementDataScreen = "tyreReplacementDataScreen";
  static const String tyreReplacementDetailScreen =
      "tyreReplacementDetailScreen";

  static Route<dynamic>? routes(RouteSettings settings) {
    StringConstants.currentRoute = settings.name ?? "";

    switch (settings.name) {
      case Screenroutes.login:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.login),
          builder: (BuildContext context) {
            return LoginScreen();
          },
        );
      case Screenroutes.dashboard:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.dashboard),
          builder: (BuildContext context) {
            return DashboardScreen();
          },
        );

      case Screenroutes.changePassword:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.changePassword),
          builder: (BuildContext context) {
            return ChangePasswordScreen();
          },
        );

      case Screenroutes.userUpdateScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.userUpdateScreen),
          builder: (BuildContext context) {
            return ChangePasswordScreen();
          },
        );

      case Screenroutes.tyreReplacementListScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.tyreReplacementListScreen,
          ),
          builder: (BuildContext context) {
            return TyreReplacementListScreen();
          },
        );
      case Screenroutes.tyreReplacementDataScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.tyreReplacementDataScreen,
          ),
          builder: (BuildContext context) {
            return TyreReplacementScreen();
          },
        );
    }
    return null;
  }
}
