import 'package:flutter/material.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));
    navService.pushReplaceNavigation(Screenroutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final iconSize = screenSize.shortestSide * 0.7; // Takes 70% of screen width

    return Scaffold(
      backgroundColor: const Color(0xFF42a5f5),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: iconSize, maxHeight: iconSize),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}
