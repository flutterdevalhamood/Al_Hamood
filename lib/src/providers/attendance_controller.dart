import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class AttendanceController with ChangeNotifier {
  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;

  // Employee list from Attendance/GetBaseList
  List<Map<String, dynamic>>? employeeData;
  int? selectedEmployeeId;

  // Location captured for the check-in
  double? latitude;
  double? longitude;

  Future<bool> _checkToken() async {
    final token = AuthRepo.token;

    if (token == null || token.isEmpty) {
      debugPrint("No token available - auth failed");
      AuthRepo.handleAuthError();
      return false;
    }

    if (AuthRepo.isTokenExpired()) {
      debugPrint("Token expired - auth failed");
      AuthRepo.handleAuthError();
      return false;
    }

    return true;
  }

  String _getAuthHeader() {
    return 'Bearer ${AuthRepo.token}';
  }

  void setSelectedEmployee(int? employeeId) {
    selectedEmployeeId = employeeId;
    notifyListeners();
  }

  void setLocation({required double lat, required double lng}) {
    latitude = lat;
    longitude = lng;
    notifyListeners();
  }

  /// Resets the form-related state after a successful submit (or on demand).
  /// Deliberately keeps [employeeData] intact so the base list doesn't need
  /// to be re-fetched.
  void clearData() {
    selectedEmployeeId = null;
    latitude = null;
    longitude = null;
    errorMessage = null;
    notifyListeners();
  }

  /// GET /api/Attendance/GetBaseList
  Future<void> getAttendanceBaseList() async {
    if (!await _checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await restApi.getAttendanceDataBaseList(
        token: _getAuthHeader(),
      );

      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        final data = response['Data'];

        // Be tolerant of the API returning either {"employees": [...]}
        // or the list directly under "Data".
        final List<dynamic> rawList;
        if (data is Map<String, dynamic>) {
          rawList = (data['employees'] as List?) ?? const [];
        } else if (data is List) {
          rawList = data;
        } else {
          rawList = const [];
        }

        employeeData =
            rawList
                .whereType<Map>()
                .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
                .toList();

        debugPrint('Employee base list fetched: ${employeeData?.length}');
      } else if (response is Map<String, dynamic>) {
        errorMessage =
            response['message']?.toString() ?? 'Failed to fetch employee list';
        debugPrint('API call failed: $errorMessage');
      } else {
        errorMessage = 'Unexpected API response format';
        debugPrint('Unexpected API response format');
      }
    } catch (e) {
      _handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postEmployeeAttendance({
    required int? employeeId,
    required double? lat,
    required double? lng,
    required MultipartFile? image,
  }) async {
    if (!await _checkToken()) return false;

    if (employeeId == null) {
      errorMessage = 'Please select an employee';
      notifyListeners();
      return false;
    }
    if (lat == null || lng == null) {
      errorMessage = 'Location is not available yet';
      notifyListeners();
      return false;
    }
    if (image == null) {
      errorMessage = 'Please capture a check-in photo';
      notifyListeners();
      return false;
    }

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      debugPrint('--- Attendance Submit Request ---');
      debugPrint('employeeId: $employeeId');
      debugPrint('latitude: $lat');
      debugPrint('longitude: $lng');
      debugPrint(
        'image -> filename: ${image.filename}, '
        'length: ${image.length} bytes, '
        'contentType: ${image.contentType}',
      );
      debugPrint('----------------------------------');
      final response = await restApi.postEmployeeAttendance(
        token: _getAuthHeader(),
        latitude: lat,
        longitude: lng,
        employeeId: employeeId,
        image: [image],
      );

      // API returns e.g. {"status": true/false, "message": "..."} —
      // note the lowercase "status" key, not "IsSuccess".
      if (response is Map<String, dynamic> && response['status'] == true) {
        debugPrint('Attendance marked successfully');
        return true;
      } else if (response is Map<String, dynamic>) {
        errorMessage =
            response['message']?.toString() ?? 'Failed to mark attendance';
        debugPrint('API call failed: $errorMessage');
        return false;
      } else {
        errorMessage = 'Unexpected API response format';
        debugPrint('Unexpected API response format');
        return false;
      }
    } catch (e) {
      _handleApiError(e);
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> postEmployeeAttendanceCheckout({
    required int? employeeId,
    required double? lat,
    required double? lng,
    required MultipartFile? image,
  }) async {
    if (!await _checkToken()) return false;

    if (employeeId == null) {
      errorMessage = 'Please select an employee';
      notifyListeners();
      return false;
    }
    if (lat == null || lng == null) {
      errorMessage = 'Location is not available yet';
      notifyListeners();
      return false;
    }
    if (image == null) {
      errorMessage = 'Please capture a check-in photo';
      notifyListeners();
      return false;
    }

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      debugPrint('--- Attendance Submit Request ---');
      debugPrint('employeeId: $employeeId');
      debugPrint('latitude: $lat');
      debugPrint('longitude: $lng');
      debugPrint(
        'image -> filename: ${image.filename}, '
        'length: ${image.length} bytes, '
        'contentType: ${image.contentType}',
      );
      debugPrint('----------------------------------');
      final response = await restApi.postEmployeeAttendanceCheckOut(
        token: _getAuthHeader(),
        latitude: lat,
        longitude: lng,
        employeeId: employeeId,
        image: [image],
      );

      // API returns e.g. {"status": true/false, "message": "..."} —
      // note the lowercase "status" key, not "IsSuccess". This is what was
      // producing the wrong snackbar color: {"status":false,"message":
      // "You have already checked out today."} was being read as success
      // because we were checking the (absent) "IsSuccess" key instead.
      if (response is Map<String, dynamic> && response['status'] == true) {
        debugPrint('Checked out successfully');
        return true;
      } else if (response is Map<String, dynamic>) {
        errorMessage =
            response['message']?.toString() ?? 'Failed to mark attendance';
        debugPrint('API call failed: $errorMessage');
        return false;
      } else {
        errorMessage = 'Unexpected API response format';
        debugPrint('Unexpected API response format');
        return false;
      }
    } catch (e) {
      _handleApiError(e);
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void _handleApiError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;

      if (status == 401) {
        debugPrint('Unauthorized - auth failed');
        AuthRepo.handleAuthError();
        errorMessage = 'Session expired. Please log in again.';
        return;
      }

      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        errorMessage = data['message'].toString();
      } else {
        errorMessage = e.message ?? 'Network error. Please try again.';
      }
      debugPrint('DioException while calling attendance API: $errorMessage');
    } else {
      errorMessage = 'Something went wrong. Please try again.';
      debugPrint('Unhandled error in AttendanceController: $e');
    }
  }
}
