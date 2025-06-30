import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class CompanyVehicleController with ChangeNotifier {
  bool isLoading = false;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;
  List<Map<String, dynamic>>? tyreData;
  List<Map<String, dynamic>>? companyVehicleOriginalData;

  List<Map<String, dynamic>>? companyVehicleData;

  String _searchQuery = '';
  List<Map<String, dynamic>>? _originalData;
  String get searchQuery => _searchQuery;

  int get filteredCount => companyVehicleData?.length ?? 0;
  int get totalCount => companyVehicleOriginalData?.length ?? 0;
  bool get isFiltered => _searchQuery.isNotEmpty;

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
  String _getAuthHeader() {
    return 'Bearer ${AuthRepo.token}';
  }

  String _selectedFilter = 'All Companies';
  String get selectedFilter => _selectedFilter;

  int getFilterCount(String filter) {
    if (companyVehicleOriginalData == null) return 0;

    if (filter == 'All Companies') {
      return companyVehicleOriginalData!.length;
    }

    return companyVehicleOriginalData!.where((item) {
      final projectName =
          item['project']?['Name']?.toString().toUpperCase() ?? '';
      return projectName == filter.toUpperCase();
    }).length;
  }

  final List<String> availableFilters = [
    'All Companies',
    'ABRAHIMI WAHID FUEL TRADING LLC',
    'AL HAMOOD GENERAL TRANSPORT EST.',
    'HAMOOD FUEL SUPPLY SERVICES LLC',
    'FOUR STARS GENERAL TRANSPORT ESTABLISHMENT',
    'OTHER COMPANY-WITH WORK PERMIT',
  ];

  // 2. Add this method to CompanyVehicleController class
  void setFilter(String filter) {
    _selectedFilter = filter;
    _applyCombinedFilter();
    notifyListeners();
  }

  Future<void> getCompanyVehicleData({bool loadMore = false}) async {
    if (!await _checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final companyVehicleResponse = await restApi.getCompanyVehiclesData(
        currentPage,
        totalPages,
        _getAuthHeader(),
      );

      if (companyVehicleResponse is Map<String, dynamic>) {
        if (companyVehicleResponse['IsSuccess'] == true) {
          final data = companyVehicleResponse['Data'] as List<dynamic>?;
          if (data != null) {
            final newCompanyVehicleData =
                data.map((v) => v as Map<String, dynamic>).toList();

            if (loadMore) {
              companyVehicleOriginalData ??= [];
              companyVehicleOriginalData!.addAll(newCompanyVehicleData);
            } else {
              companyVehicleOriginalData = List.from(newCompanyVehicleData);
              currentPage = 1;
            }

            hasMore = data.length == totalPages;

            // Apply current filters
            _applyCombinedFilter();
          } else {
            hasMore = false;
            if (!loadMore) {
              companyVehicleData = [];
              companyVehicleOriginalData = [];
            }
          }
        } else {
          errorMessage = companyVehicleResponse['Message'] ?? 'API call failed';
          debugPrint('API call failed: $errorMessage');
        }
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

  void loadMore() {
    if (hasMore && !isLoading) {
      currentPage++;
      getCompanyVehicleData(loadMore: true);
    }
  }

  void searchCompanyVehicles(String query) {
    _searchQuery = query.trim();
    _applyCombinedFilter();
    notifyListeners();
  }

  void _applyCombinedFilter() {
    if (companyVehicleOriginalData == null) return;

    companyVehicleData =
        companyVehicleOriginalData!.where((item) {
          // Apply search filter
          bool matchesSearch = true;
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final plateNo1 = item['PlateNo1']?.toString().toLowerCase() ?? '';
            final plateNo2 = item['PlateNo2']?.toString().toLowerCase() ?? '';
            matchesSearch =
                plateNo1.contains(query) || plateNo2.contains(query);
          }

          // Apply company filter
          bool matchesCompany = true;
          if (_selectedFilter != 'All Companies') {
            final projectName =
                item['project']?['Name']?.toString().toUpperCase() ?? '';
            matchesCompany = projectName == _selectedFilter.toUpperCase();
          }

          return matchesSearch && matchesCompany;
        }).toList();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyCombinedFilter();
    notifyListeners();
  }

  Future<void> refreshData() async {
    currentPage = 1;
    hasMore = true;
    await getCompanyVehicleData();
  }

  void clearData() {
    companyVehicleData = null;
    companyVehicleOriginalData = null;
    currentPage = 1;
    hasMore = true;
    errorMessage = null;
    _searchQuery = '';
    notifyListeners();
  }

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
