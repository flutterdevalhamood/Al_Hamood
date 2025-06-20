import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../repo/auth_repo.dart';

class DashboardController with ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  int? id;
  Map<String, dynamic>? cashOnHand;
  Map<String, dynamic>? amountInBank;
  Map<String, dynamic>? investorPayable;

  Future<bool> _checkToken() async {
    final token = AuthRepo.token;

    // Check if token is valid
    if (token == null || token.isEmpty) {
      debugPrint("No token available - auth failed");
      // Handle missing token
      AuthRepo.handleAuthError();
      return false;
    }

    // Check if token is expired (if implementation supports it)
    if (AuthRepo.isTokenExpired()) {
      debugPrint("Token expired - auth failed");
      // Handle expired token
      AuthRepo.handleAuthError();
      return false;
    }

    return true;
  }

  // Format the token with Bearer prefix
  // String _getAuthHeader() {
  //   return 'Bearer ${AuthRepo.token}';
  // }

  // Future<void> getInvestorBaseData() async {
  //   if (!await _checkToken()) return;
  //
  //   isLoading = true;
  //   notifyListeners();
  //
  //   try {
  //     final adminDashboardData = await restApi.getAdminDashboardData(
  //       token: _getAuthHeader(),
  //     );
  //
  //     if (adminDashboardData['IsSuccess'] == true) {
  //       cashOnHand = Map<String, dynamic>.from(
  //         adminDashboardData['Data']['cash_on_hand'],
  //       );
  //       amountInBank = Map<String, dynamic>.from(
  //         adminDashboardData['Data']['amount_in_bank'],
  //       );
  //       investorPayable = Map<String, dynamic>.from(
  //         adminDashboardData['Data']['investor_payable'],
  //       );
  //
  //       debugPrint('Base data fetched successfully');
  //     } else {
  //       debugPrint('API call failed: ${adminDashboardData['Message']}');
  //       errorMessage =
  //           adminDashboardData['Message'] ?? 'Failed to fetch base data';
  //     }
  //   } catch (e) {
  //     _handleApiError(e);
  //   } finally {
  //     isLoading = false;
  //     notifyListeners();
  //   }
  // }

  // Standardized error handling
  dynamic _handleApiError(dynamic e) {
    if (e is DioException) {
      debugPrint("Dio Exception: ${e.message}");

      // Handle redirect to login (authentication failure)
      if (e.response?.statusCode == 302 ||
          (e.response?.data is String &&
              (e.response?.data as String).contains('login'))) {
        debugPrint("Authentication failed - redirected to login page");
        errorMessage = 'Authentication failed. Please log in again.';
        AuthRepo.handleAuthError();
        return false;
      }

      // Log detailed response information
      if (e.response != null) {
        debugPrint('Response status: ${e.response?.statusCode}');
        debugPrint('Response data: ${e.response?.data}');
      }

      errorMessage = 'Network error: ${e.message}';
    } else {
      debugPrint("Error: $e");
      errorMessage = 'Error: ${e.toString()}';
    }
    return false;
  }
}
