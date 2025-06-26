import 'package:flutter/material.dart';
import 'package:sample/src/screens/change_password_screen.dart';
import 'package:sample/src/screens/swapTyre/swap_tyre_data_screen.dart';
import 'package:sample/src/screens/swapTyre/swap_tyre_list_screen.dart';
import 'package:sample/src/screens/swapTyre/swap_tyre_picture_upload_screen.dart';
import 'package:sample/src/screens/tyreReplacement/tyre_replacement_data_screen.dart';
import 'package:sample/src/screens/tyreReplacement/tyre_replacement_list_screen.dart';
import 'package:sample/src/screens/tyreReplacement/tyre_replacement_picture_upload_screen.dart';

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
  static const String tyreReplacementPictureUploadScreen =
      "tyreReplacementPictureUploadScreen";

  //swap tyre
  static const String swapTyreListScreen = "swapTyreListScreen";
  static const String swapTyreDataScreen = "swapTyreDataScreen";
  static const String swapTyreDetailScreen = "swapTyreDetailScreen";
  static const String swapTyrePictureUploadScreen =
      "swapTyrePictureUploadScreen";

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

      case Screenroutes.tyreReplacementPictureUploadScreen:
        return MaterialPageRoute(
          settings: RouteSettings(
            name: Screenroutes.tyreReplacementPictureUploadScreen,
          ),
          builder: (BuildContext context) {
            return TyreReplacementPictureUploadScreen();
          },
        );

      case Screenroutes.swapTyreListScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.swapTyreListScreen),
          builder: (BuildContext context) {
            return SwapTyreListScreen();
          },
        );
      case Screenroutes.swapTyreDataScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(name: Screenroutes.swapTyreDataScreen),
          builder: (BuildContext context) {
            return SwapTyreDataScreen();
          },
        );

      case Screenroutes.swapTyrePictureUploadScreen:
        return MaterialPageRoute(
          settings: RouteSettings(
            name: Screenroutes.swapTyrePictureUploadScreen,
          ),
          builder: (BuildContext context) {
            return SwapTyrePictureUploadScreen();
          },
        );
    }
    return null;
  }
}
