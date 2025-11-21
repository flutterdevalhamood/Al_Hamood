// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:sample/src/util/app_navigation.dart';
// import 'package:sample/src/util/app_routes.dart';
//
// import '../data/rest_client.dart';
// import '../repo/auth_repo.dart';
//
// class CompanyVehicleController with ChangeNotifier {
//   bool isLoading = false;
//   int currentPage = 1;
//   final int itemsPerPage = 100;
//   bool hasMore = true;
//   String? errorMessage;
//   int? id;
//   List<Map<String, dynamic>>? tyreData;
//   List<Map<String, dynamic>>? companyVehicleOriginalData;
//
//   List<Map<String, dynamic>>? companyVehicleData;
//
//   String _searchQuery = '';
//   List<Map<String, dynamic>>? _originalData;
//   String get searchQuery => _searchQuery;
//
//   int get filteredCount => companyVehicleData?.length ?? 0;
//   int get totalCount => companyVehicleOriginalData?.length ?? 0;
//   bool get isFiltered => _searchQuery.isNotEmpty;
//
//   String? tyreReplacementReportUrl;
//   List<Map<String, dynamic>>? companies;
//
//   Future<bool> _checkToken() async {
//     final token = AuthRepo.token;
//
//     // Check if token is valid
//     if (token == null || token.isEmpty) {
//       debugPrint("No token available - auth failed");
//       // Handle missing token
//       AuthRepo.handleAuthError();
//       return false;
//     }
//
//     // Check if token is expired (if implementation supports it)
//     if (AuthRepo.isTokenExpired()) {
//       debugPrint("Token expired - auth failed");
//       // Handle expired token
//       AuthRepo.handleAuthError();
//       return false;
//     }
//
//     return true;
//   }
//
//   // Format the token with Bearer prefix
//   String _getAuthHeader() {
//     return 'Bearer ${AuthRepo.token}';
//   }
//
//   String _selectedFilter = 'All Companies';
//   String get selectedFilter => _selectedFilter;
//
//   int getFilterCount(String filter) {
//     if (companyVehicleOriginalData == null) return 0;
//
//     if (filter == 'All Companies') {
//       return companyVehicleOriginalData!.length;
//     }
//
//     return companyVehicleOriginalData!.where((item) {
//       final projectName = item['project']?['Name']?.toString() ?? '';
//       // Use exact match since we're using exact names from API
//       return projectName == filter;
//     }).length;
//   }
//
//   // Remove the hardcoded list and replace with a getter
//   List<String> get availableFilters {
//     if (companyVehicleOriginalData == null ||
//         companyVehicleOriginalData!.isEmpty) {
//       return ['All Companies'];
//     }
//
//     // Extract unique company names from the data
//     Set<String> companies = {'All Companies'};
//
//     for (var item in companyVehicleOriginalData!) {
//       final projectName = item['project']?['Name']?.toString() ?? '';
//       if (projectName.isNotEmpty) {
//         companies.add(projectName);
//       }
//     }
//
//     return companies.toList()..sort((a, b) {
//       // Keep "All Companies" at the top
//       if (a == 'All Companies') return -1;
//       if (b == 'All Companies') return 1;
//       return a.compareTo(b);
//     });
//   }
//
//   // 2. Add this method to CompanyVehicleController class
//   void setFilter(String filter) {
//     _selectedFilter = filter;
//     _applyCombinedFilter();
//     notifyListeners();
//   }
//
//   Future<void> getCompanyVehicleData({bool loadMore = false}) async {
//     if (!await _checkToken()) return;
//
//     isLoading = true;
//     errorMessage = null;
//     notifyListeners();
//
//     try {
//       final companyVehicleResponse = await restApi.getCompanyVehiclesData(
//         currentPage,
//         itemsPerPage, // Pass itemsPerPage instead of totalPages
//         _getAuthHeader(),
//       );
//
//       if (companyVehicleResponse is Map<String, dynamic>) {
//         if (companyVehicleResponse['IsSuccess'] == true) {
//           final data = companyVehicleResponse['Data'] as List<dynamic>?;
//           if (data != null) {
//             final newCompanyVehicleData =
//                 data.map((v) => v as Map<String, dynamic>).toList();
//
//             if (loadMore) {
//               companyVehicleOriginalData ??= [];
//               companyVehicleOriginalData!.addAll(newCompanyVehicleData);
//             } else {
//               companyVehicleOriginalData = List.from(newCompanyVehicleData);
//               currentPage = 1;
//             }
//
//             // Check if there are more pages
//             // If we received fewer items than requested, we've reached the end
//             hasMore = data.length == itemsPerPage;
//
//             // Apply current filters
//             _applyCombinedFilter();
//           } else {
//             hasMore = false;
//             if (!loadMore) {
//               companyVehicleData = [];
//               companyVehicleOriginalData = [];
//             }
//           }
//         } else {
//           errorMessage = companyVehicleResponse['Message'] ?? 'API call failed';
//           debugPrint('API call failed: $errorMessage');
//         }
//       } else {
//         errorMessage = 'Unexpected API response format';
//         debugPrint('Unexpected API response format');
//       }
//     } catch (e) {
//       _handleApiError(e);
//     } finally {
//       isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   Future<void> getCompanyVehicleAssignmentBaseData() async {
//     if (!await _checkToken()) return;
//
//     isLoading = true;
//     notifyListeners();
//
//     try {
//       final companyAssignmentBaseData = await restApi
//           .getCompanyVehicleAssignmentBaseList(token: _getAuthHeader());
//
//       if (companyAssignmentBaseData['IsSuccess'] == true) {
//         companies = List<Map<String, dynamic>>.from(
//           companyAssignmentBaseData['Data']['companies'],
//         );
//       } else {
//         debugPrint('API call failed: ${companyAssignmentBaseData['Message']}');
//         errorMessage =
//             companyAssignmentBaseData['Message'] ?? 'Failed to fetch base data';
//       }
//     } catch (e) {
//       _handleApiError(e);
//     } finally {
//       isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   Future<bool> postAssignCompanyVehicle({
//     int? companyVehicleId,
//     String? assignedAt,
//     String? remarks,
//     int? companyId,
//   }) async {
//     if (!await _checkToken()) return false;
//
//     try {
//       final response = await restApi.postAssignCompanyVehicle(
//         token: _getAuthHeader(),
//         companyVehicleId: companyVehicleId,
//         assignedAt: assignedAt,
//         remarks: remarks,
//         companyId: companyId,
//       );
//
//       if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
//         getCompanyVehicleData();
//         NavigationService().pushNavigation(Screenroutes.companyVehicleScreen);
//         return true;
//       } else if (response is Map<String, dynamic>) {
//         errorMessage = response['Message'] ?? 'Failed to assign vehicle';
//       } else {
//         debugPrint("Unknown response format");
//         errorMessage = 'Unexpected response format';
//       }
//       return false;
//     } catch (e) {
//       return _handleApiError(e);
//     }
//   }
//
//   Future<bool> postCompanyVehicleReports(
//     String? fromDate,
//     String? toDate,
//     String? vehicleId,
//   ) async {
//     if (!await _checkToken()) return false;
//
//     try {
//       final tyreReplacementReportsData = await restApi
//           .postTyreREplacementReport(
//             token: _getAuthHeader(),
//             fromDate: fromDate,
//             toDate: toDate,
//             vehicleId: vehicleId,
//           );
//
//       if (tyreReplacementReportsData['IsSuccess'] == true) {
//         final data = tyreReplacementReportsData['Data'];
//
//         if (data is String && data.isNotEmpty) {
//           tyreReplacementReportUrl = data;
//         } else if (data is Map && data.containsKey('url')) {
//           tyreReplacementReportUrl = data['url']?.toString();
//         } else {
//           errorMessage = 'No report URL received from server';
//           return false;
//         }
//
//         // Validate that we got a valid URL
//         if (tyreReplacementReportUrl == null ||
//             tyreReplacementReportUrl!.isEmpty) {
//           errorMessage = 'Invalid report URL received';
//           return false;
//         }
//
//         notifyListeners();
//         return true;
//       } else {
//         errorMessage =
//             tyreReplacementReportsData['Message'] ??
//             'Failed to generate report';
//         return false;
//       }
//     } catch (e) {
//       errorMessage = 'An error occurred while generating the report';
//       return _handleApiError(e);
//     }
//   }
//
//   void loadMore() {
//     if (hasMore && !isLoading) {
//       currentPage++;
//       getCompanyVehicleData(loadMore: true);
//     }
//   }
//
//   void searchCompanyVehicles(String query) {
//     _searchQuery = query.trim();
//     _applyCombinedFilter();
//     notifyListeners();
//   }
//
//   void _applyCombinedFilter() {
//     if (companyVehicleOriginalData == null) return;
//
//     companyVehicleData =
//         companyVehicleOriginalData!.where((item) {
//           // Apply search filter
//           bool matchesSearch = true;
//           if (_searchQuery.isNotEmpty) {
//             final query = _searchQuery.toLowerCase();
//             final plateNo1 = item['PlateNo1']?.toString().toLowerCase() ?? '';
//             final plateNo2 = item['PlateNo2']?.toString().toLowerCase() ?? '';
//             matchesSearch =
//                 plateNo1.contains(query) || plateNo2.contains(query);
//           }
//
//           // Apply company filter
//           bool matchesCompany = true;
//           if (_selectedFilter != 'All Companies') {
//             final projectName = item['project']?['Name']?.toString() ?? '';
//             // Use case-sensitive exact match since we're now using exact names from API
//             matchesCompany = projectName == _selectedFilter;
//           }
//
//           return matchesSearch && matchesCompany;
//         }).toList();
//   }
//
//   void clearSearch() {
//     _searchQuery = '';
//     _applyCombinedFilter();
//     notifyListeners();
//   }
//
//   Future<void> refreshData() async {
//     currentPage = 1;
//     hasMore = true;
//     companyVehicleData = null;
//     companyVehicleOriginalData = null;
//     await getCompanyVehicleData();
//   }
//
//   void clearData() {
//     companyVehicleData = null;
//     companyVehicleOriginalData = null;
//     currentPage = 1;
//     hasMore = true;
//     errorMessage = null;
//     _searchQuery = '';
//     _selectedFilter = 'All Companies';
//     notifyListeners();
//   }
//
//   // Standardized error handling
//   dynamic _handleApiError(dynamic e) {
//     if (e is DioException) {
//       debugPrint("Dio Exception: ${e.message}");
//
//       // Handle redirect to login (authentication failure)
//       if (e.response?.statusCode == 302 ||
//           (e.response?.data is String &&
//               (e.response?.data as String).contains('login'))) {
//         debugPrint("Authentication failed - redirected to login page");
//         errorMessage = 'Authentication failed. Please log in again.';
//         AuthRepo.handleAuthError();
//         return false;
//       }
//
//       // Log detailed response information
//       if (e.response != null) {
//         debugPrint('Response status: ${e.response?.statusCode}');
//         debugPrint('Response data: ${e.response?.data}');
//       }
//
//       errorMessage = 'Network error: ${e.message}';
//     } else {
//       debugPrint("Error: $e");
//       errorMessage = 'Error: ${e.toString()}';
//     }
//     return false;
//   }
// }

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class CompanyVehicleController with ChangeNotifier {
  bool isLoading = false;
  int currentPage = 1;
  final int itemsPerPage = 100;
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

  String? tyreReplacementReportUrl;
  List<Map<String, dynamic>>? companies;

  // New property to store current vehicle details
  Map<String, dynamic>? currentVehicleDetails;

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
      final projectName = item['project']?['Name']?.toString() ?? '';
      // Use exact match since we're using exact names from API
      return projectName == filter;
    }).length;
  }

  // Remove the hardcoded list and replace with a getter
  List<String> get availableFilters {
    if (companyVehicleOriginalData == null ||
        companyVehicleOriginalData!.isEmpty) {
      return ['All Companies'];
    }

    // Extract unique company names from the data
    Set<String> companies = {'All Companies'};

    for (var item in companyVehicleOriginalData!) {
      final projectName = item['project']?['Name']?.toString() ?? '';
      if (projectName.isNotEmpty) {
        companies.add(projectName);
      }
    }

    return companies.toList()..sort((a, b) {
      // Keep "All Companies" at the top
      if (a == 'All Companies') return -1;
      if (b == 'All Companies') return 1;
      return a.compareTo(b);
    });
  }

  // 2. Add this method to CompanyVehicleController class
  void setFilter(String filter) {
    _selectedFilter = filter;
    _applyCombinedFilter();
    notifyListeners();
  }

  // New method to get vehicle details by ID
  Future<void> getVehicleDetails(int vehicleId) async {
    if (!await _checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Find the vehicle in the existing data first
      if (companyVehicleOriginalData != null) {
        final vehicle = companyVehicleOriginalData!.firstWhere(
          (v) => v['id'] == vehicleId,
          orElse: () => {},
        );

        if (vehicle.isNotEmpty) {
          currentVehicleDetails = vehicle;
          isLoading = false;
          notifyListeners();
          return;
        }
      }

      // If not found in existing data, fetch from API
      // This assumes you have an API endpoint to get a single vehicle
      // If not, we'll fetch all vehicles and find the one we need
      final response = await restApi.getCompanyVehiclesData(
        1,
        itemsPerPage,
        _getAuthHeader(),
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          final data = response['Data'] as List<dynamic>?;
          if (data != null) {
            final vehicleList =
                data.map((v) => v as Map<String, dynamic>).toList();

            // Find the specific vehicle
            final vehicle = vehicleList.firstWhere(
              (v) => v['id'] == vehicleId,
              orElse: () => {},
            );

            if (vehicle.isNotEmpty) {
              currentVehicleDetails = vehicle;
            } else {
              errorMessage = 'Vehicle not found';
              debugPrint('Vehicle with ID $vehicleId not found');
            }
          }
        } else {
          errorMessage =
              response['Message'] ?? 'Failed to fetch vehicle details';
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

  Future<void> getCompanyVehicleData({bool loadMore = false}) async {
    if (!await _checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final companyVehicleResponse = await restApi.getCompanyVehiclesData(
        currentPage,
        itemsPerPage, // Pass itemsPerPage instead of totalPages
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

            // Check if there are more pages
            // If we received fewer items than requested, we've reached the end
            hasMore = data.length == itemsPerPage;

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

  Future<void> getCompanyVehicleAssignmentBaseData() async {
    if (!await _checkToken()) return;

    isLoading = true;
    notifyListeners();

    try {
      final companyAssignmentBaseData = await restApi
          .getCompanyVehicleAssignmentBaseList(token: _getAuthHeader());

      if (companyAssignmentBaseData['IsSuccess'] == true) {
        companies = List<Map<String, dynamic>>.from(
          companyAssignmentBaseData['Data']['companies'],
        );
      } else {
        debugPrint('API call failed: ${companyAssignmentBaseData['Message']}');
        errorMessage =
            companyAssignmentBaseData['Message'] ?? 'Failed to fetch base data';
      }
    } catch (e) {
      _handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postAssignCompanyVehicle({
    int? companyVehicleId,
    String? assignedAt,
    String? remarks,
    int? companyId,
  }) async {
    if (!await _checkToken()) return false;

    try {
      final response = await restApi.postAssignCompanyVehicle(
        token: _getAuthHeader(),
        companyVehicleId: companyVehicleId,
        assignedAt: assignedAt,
        remarks: remarks,
        companyId: companyId,
      );

      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        getCompanyVehicleData();
        NavigationService().pushNavigation(Screenroutes.companyVehicleScreen);
        return true;
      } else if (response is Map<String, dynamic>) {
        errorMessage = response['Message'] ?? 'Failed to assign vehicle';
      } else {
        debugPrint("Unknown response format");
        errorMessage = 'Unexpected response format';
      }
      return false;
    } catch (e) {
      return _handleApiError(e);
    }
  }

  Future<bool> postCompanyVehicleReports(
    String? fromDate,
    String? toDate,
    String? vehicleId,
  ) async {
    if (!await _checkToken()) return false;

    try {
      final tyreReplacementReportsData = await restApi
          .postTyreREplacementReport(
            token: _getAuthHeader(),
            fromDate: fromDate,
            toDate: toDate,
            vehicleId: vehicleId,
          );

      if (tyreReplacementReportsData['IsSuccess'] == true) {
        final data = tyreReplacementReportsData['Data'];

        if (data is String && data.isNotEmpty) {
          tyreReplacementReportUrl = data;
        } else if (data is Map && data.containsKey('url')) {
          tyreReplacementReportUrl = data['url']?.toString();
        } else {
          errorMessage = 'No report URL received from server';
          return false;
        }

        // Validate that we got a valid URL
        if (tyreReplacementReportUrl == null ||
            tyreReplacementReportUrl!.isEmpty) {
          errorMessage = 'Invalid report URL received';
          return false;
        }

        notifyListeners();
        return true;
      } else {
        errorMessage =
            tyreReplacementReportsData['Message'] ??
            'Failed to generate report';
        return false;
      }
    } catch (e) {
      errorMessage = 'An error occurred while generating the report';
      return _handleApiError(e);
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
            final projectName = item['project']?['Name']?.toString() ?? '';
            // Use case-sensitive exact match since we're now using exact names from API
            matchesCompany = projectName == _selectedFilter;
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
    companyVehicleData = null;
    companyVehicleOriginalData = null;
    await getCompanyVehicleData();
  }

  void clearData() {
    companyVehicleData = null;
    companyVehicleOriginalData = null;
    currentVehicleDetails = null; // Clear current vehicle details
    currentPage = 1;
    hasMore = true;
    errorMessage = null;
    _searchQuery = '';
    _selectedFilter = 'All Companies';
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
