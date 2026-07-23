import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sample/src/models/user_model.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

import '../config/messages.dart';
import '../data/rest_client.dart';
import '../repo/auth_repo.dart';
import '../util/circle_progress.dart';
import '../util/snack.dart';

class AuthController with ChangeNotifier {
  final token = AuthRepo.token;
  String? contactNumber;
  UserData? userData;

  Future<void> login(String email, String password) async {
    showCircle();

    try {
      final loginResponse = await restApi.login(
        email: email,
        password: password,
      );

      if (loginResponse.IsSuccess == true) {
        userData = loginResponse.Data;
        AuthRepo.token = loginResponse.Token;
        AuthRepo.loginId = loginResponse.Data?.id;
        AuthRepo.user = loginResponse.Data?.name;
        AuthRepo.contact = loginResponse.Data?.contactNumber;
        notifyListeners();
        NavigationService().pushNavigation(Screenroutes.dashboard);
      } else {
        showErrorSnack(Messages.authenticationFailure);
      }
    } catch (e) {
      if (e is TypeError) {
        if (e is DioException) {
          log("TypeError", stackTrace: e.stackTrace);
          log("TypeError", stackTrace: e.stackTrace);
        }
        log("TypeError", stackTrace: e.stackTrace);
      }
      showErrorSnack(Messages.authenticationFailure);
    }

    removeCircle();
  }

  Future<bool> logout(int? loginId) async {
    showCircle();

    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.logout(token: 'Bearer $token', id: AuthRepo.loginId);
      return true;
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
    }
  }

  Future<bool> changePassword(
    String? currentPassword,
    String? newPassword,
  ) async {
    showCircle();

    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.changePassword(
        token: 'Bearer $token',
        currentPassword: currentPassword,
        password: newPassword,
      );
      return true;
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
    }
  }
}
