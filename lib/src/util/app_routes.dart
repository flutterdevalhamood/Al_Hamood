import 'package:flutter/material.dart';
import 'package:sample/src/screens/change_password_screen.dart';
import 'package:sample/src/screens/reports/companyVehicle/vehicle_assignment_screen.dart';
import 'package:sample/src/screens/reports/tyre_replacement_report_screen.dart';
import 'package:sample/src/screens/swapTyre/swap_tyre_data_screen.dart';
import 'package:sample/src/screens/swapTyre/swap_tyre_list_screen.dart';
import 'package:sample/src/screens/tyreReplacement/tyre_replacement_data_screen.dart';
import 'package:sample/src/screens/tyreReplacement/tyre_replacement_list_screen.dart';
import 'package:sample/src/screens/tyreReplacement/tyre_replacement_picture_upload_screen.dart';

import '../constants/string_constants.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/reports/companyVehicle/company_vehicle_screen.dart';

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

  static const String companyVehicleScreen = "companyVehicleScreen";
  static const String tyreReplacementReportScreen =
      "tyreReplacementReportsScreen";
  static const String vehicleAssignmentScreen = "vehicleAssignmentScreen";

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

      case Screenroutes.companyVehicleScreen:
        return MaterialPageRoute(
          settings: RouteSettings(name: Screenroutes.companyVehicleScreen),
          builder: (BuildContext context) {
            return CompanyVehicleScreen();
          },
        );

      case Screenroutes.tyreReplacementReportScreen:
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.tyreReplacementReportScreen,
          ),
          builder: (BuildContext context) {
            return TyreReplacementReportScreen();
          },
        );

      case Screenroutes.vehicleAssignmentScreen:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          settings: const RouteSettings(
            name: Screenroutes.vehicleAssignmentScreen,
          ),
          builder: (BuildContext context) {
            return VehicleAssignmentScreen(
              vehicleId: args['vehicleId'],
              vehicleName: args['vehicleName'],
              plateNumber: args['plateNumber'],
            );
          },
        );
    }
    return null;
  }
}
