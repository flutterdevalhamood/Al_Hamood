import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/BaseScreen.dart';
import 'package:sample/src/providers/company_vehicle_controller.dart';
import 'package:sample/src/providers/login_controller.dart';
import 'package:sample/src/providers/swap_tyre_controller.dart';
import 'package:sample/src/providers/tyre_replacement_controller.dart';
import 'package:sample/src/util/shared_pref.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/repo/auth_repo.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AuthRepo.initAuth();
  prefs = await SharedPreferences.getInstance();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthController()),

        ChangeNotifierProvider(
          create: (context) => TyreReplacementController(),
        ),
        ChangeNotifierProvider(create: (context) => SwapTyreController()),
        ChangeNotifierProvider(create: (context) => CompanyVehicleController()),
      ],
      child: const BaseScreen(),
    ),
  );
}
