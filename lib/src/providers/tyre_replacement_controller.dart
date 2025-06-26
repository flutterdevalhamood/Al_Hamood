import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class TyreReplacementController with ChangeNotifier {
  bool isLoading = false;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;
  List<Map<String, dynamic>>? tyreData;
  List<Map<String, dynamic>>? tyreOriginalData;
  List<Map<String, dynamic>>? tyreVersion;
  List<Map<String, dynamic>>? supplierData;
  List<Map<String, dynamic>>? companyVehicleData;
  List<Map<String, dynamic>>? tyreReplacementData;
  List<Map<String, dynamic>>? tyreCodesOfVersionData;
  String? reportUrl;

  String _searchQuery = '';
  List<Map<String, dynamic>>? _originalData;
  String get searchQuery => _searchQuery;

  int get filteredCount => tyreReplacementData?.length ?? 0;
  int get totalCount => tyreOriginalData?.length ?? 0;
  bool get isFiltered => _searchQuery.isNotEmpty;

  int? selectedVehicleId;
  int? selectedVersionId;
  int? selectedTyreCodeId;
  int? selectedSupplierId;

  bool _isLoadingTyreVersions = false;
  bool get isLoadingTyreVersions => _isLoadingTyreVersions;

  int? lastCreatedTyreReplacementId;

  void setVehicleType(int? vehicleTypeId) {
    selectedVehicleId = vehicleTypeId;
    notifyListeners();
  }

  void setVersionType(int? versionTypeId) {
    selectedVersionId = versionTypeId;
    notifyListeners();
  }

  void setVTyreCode(int? tyreCodeId) {
    selectedTyreCodeId = tyreCodeId;
    notifyListeners();
  }

  void setSupplier(int? supplierId) {
    selectedSupplierId = supplierId;
    notifyListeners();
  }

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

  Future<void> getTyreReplacementData({bool loadMore = false}) async {
    if (!await _checkToken()) return;

    isLoading = true;
    errorMessage = null; // Clear previous errors
    notifyListeners();

    try {
      final tyreReplacement = await restApi.getTyreReplacement(
        currentPage,
        totalPages,
        _getAuthHeader(),
      );

      if (tyreReplacement is Map<String, dynamic>) {
        if (tyreReplacement['IsSuccess'] == true) {
          final data = tyreReplacement['Data'] as List<dynamic>?;
          if (data != null) {
            final newTyreReplacementData =
                data.map((v) => v as Map<String, dynamic>).toList();

            if (loadMore) {
              tyreOriginalData ??= [];
              tyreOriginalData!.addAll(newTyreReplacementData);
              tyreReplacementData ??= [];
              tyreReplacementData!.addAll(newTyreReplacementData);
            } else {
              tyreOriginalData = List.from(newTyreReplacementData);
              tyreReplacementData = List.from(newTyreReplacementData);
              currentPage = 1; // Reset page on fresh load
            }

            hasMore = data.length == totalPages;

            // Apply current search filter if any
            if (_searchQuery.isNotEmpty) {
              _applySearchFilter();
            }
          } else {
            hasMore = false;
            if (!loadMore) {
              tyreReplacementData = [];
              tyreOriginalData = [];
            }
          }
        } else {
          errorMessage = tyreReplacement['Message'] ?? 'API call failed';
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
      getTyreReplacementData(loadMore: true);
    }
  }

  void searchTyreReplacements(String query) {
    _searchQuery = query.trim();
    _applySearchFilter();
    notifyListeners();
  }

  void _applySearchFilter() {
    if (tyreOriginalData == null) return;

    if (_searchQuery.isEmpty) {
      tyreReplacementData = List.from(tyreOriginalData!);
    } else {
      final query = _searchQuery.toLowerCase();
      tyreReplacementData =
          tyreOriginalData!.where((item) {
            final plateNo =
                item['company_vehicle']?['PlateNo1']
                    ?.toString()
                    .toLowerCase() ??
                '';

            return plateNo.contains(query);
          }).toList();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    if (tyreOriginalData != null) {
      tyreReplacementData = List.from(tyreOriginalData!);
    }
    notifyListeners();
  }

  Future<void> refreshData() async {
    currentPage = 1;
    hasMore = true;
    await getTyreReplacementData();
  }

  void clearData() {
    selectedVehicleId = null;
    selectedVersionId = null;
    selectedTyreCodeId = null;
    selectedSupplierId = null;
    tyreReplacementData = null;
    tyreOriginalData = null;
    currentPage = 1;
    hasMore = true;
    errorMessage = null;
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> getTyreReplacementDetail() async {
    if (!await _checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (id == null) {
        throw Exception("Customer ID is required");
      }

      final tyreReplacementDetailData = await restApi.getTyreReplacementDetail(
        id: id,
        token: _getAuthHeader(),
      );

      if (tyreReplacementDetailData['IsSuccess'] == true) {
        final data = tyreReplacementDetailData['Data'] as Map<String, dynamic>;
        tyreData = [data];
        debugPrint('Assigned units fetched: ${tyreData?.length}');
      } else {
        errorMessage =
            tyreReplacementDetailData['Message'] ??
            'Failed to fetch assigned units';
        debugPrint('API call failed: $errorMessage');
      }
    } catch (e) {
      _handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getTyreReplacementBaseData() async {
    if (!await _checkToken()) return;

    isLoading = true;
    notifyListeners();

    try {
      final tyreReplacementBaseData = await restApi.getTyreReplacementBaseList(
        token: _getAuthHeader(),
      );

      if (tyreReplacementBaseData['IsSuccess'] == true) {
        tyreVersion = List<Map<String, dynamic>>.from(
          tyreReplacementBaseData['Data']['tyre_version'],
        );
        supplierData = List<Map<String, dynamic>>.from(
          tyreReplacementBaseData['Data']['suppliers'],
        );
        companyVehicleData = List<Map<String, dynamic>>.from(
          tyreReplacementBaseData['Data']['company_vehicles'],
        );
        debugPrint('Base data fetched successfully');
      } else {
        debugPrint('API call failed: ${tyreReplacementBaseData['Message']}');
        errorMessage =
            tyreReplacementBaseData['Message'] ?? 'Failed to fetch base data';
      }
    } catch (e) {
      _handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postTyreReplacement({
    int? companyVehicleId,
    int? vehicleTyreCodeId,
    int? supplierID,
    String? brand,
    String? tyreChangeDate,
    String? currentOdometer,
    String? reasonForChange,
    String? changedBy,
    List<MultipartFile>? odometerImages,
  }) async {
    if (!await _checkToken()) return false;

    try {
      final response = await restApi.postTyreReplacement(
        token: _getAuthHeader(),
        companyVehicleId: companyVehicleId,
        vehicleTyreCodeId: vehicleTyreCodeId,
        supplierId: supplierID,
        brand: brand,
        tyreChangeDate: tyreChangeDate,
        currentOdometer: currentOdometer,
        reasonForChange: reasonForChange,
        changedBy: changedBy,
        files: odometerImages,
      );

      // Check response
      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        // lastCreatedTyreReplacementId =
        //     response['Data']?['Id'] ?? response['Id'];
        getTyreReplacementData();
        NavigationService().pushNavigation(
          Screenroutes.tyreReplacementListScreen,
        );
        return true;
      } else if (response is Map<String, dynamic>) {
        debugPrint(
          "Transaction failed: ${response['Message'] ?? 'Unknown error'}",
        );
        errorMessage = response['Message'] ?? 'Failed to save transaction';
      } else {
        debugPrint("Unknown response format");
        errorMessage = 'Unexpected response format';
      }
      return false;
    } catch (e) {
      return _handleApiError(e);
    }
  }

  Future<void> getTyreCodesOfVersion(int selectedVersionId) async {
    if (!await _checkToken()) return;

    _isLoadingTyreVersions = true;
    tyreCodesOfVersionData = null;
    notifyListeners();

    try {
      final tyreCodeOfVersionResponse = await restApi.getTyreCodeOfVersion(
        id: selectedVersionId,
        token: _getAuthHeader(),
      );

      if (tyreCodeOfVersionResponse['IsSuccess'] == true) {
        final tyreCodesData = List<Map<String, dynamic>>.from(
          tyreCodeOfVersionResponse['Data'] ?? [],
        );

        tyreCodesOfVersionData =
            tyreCodesData.map((item) {
              return {
                'id': item['id'].toString(),
                'Code': item['Code'],
                'display_name': item['Code'], // Use Code for display
              };
            }).toList();

        debugPrint(
          'Tyre version data fetched successfully: ${tyreCodesOfVersionData?.length} invoices',
        );
        debugPrint('Tyre versions: ${tyreCodesData.join(', ')}');
      } else {
        debugPrint('API call failed: ${tyreCodeOfVersionResponse['Message']}');
        // Don't set main errorMessage here to avoid affecting main screen
        tyreCodesOfVersionData = []; // Set empty list on failure
      }
    } catch (e) {
      debugPrint('Error fetching invoices: $e');
      tyreCodesOfVersionData = []; // Set empty list on error
      // Don't call _handleApiError here as it might affect main loading state
    } finally {
      _isLoadingTyreVersions = false;
      notifyListeners();
    }
  }

  void clearInvoicesOfProduct() {
    tyreCodesOfVersionData = null;
    notifyListeners();
  }

  Future<void> deleteTyreReplacement(int? id, String? descriptionText) async {
    if (!await _checkToken()) return;

    try {
      await restApi.deleteTyreReplacement(
        token: _getAuthHeader(),
        id: id,
        description: descriptionText,
      );
      await getTyreReplacementData();
    } catch (e) {
      _handleApiError(e);
    }
  }

  Future<bool> postTyreReplacementPictureUpload({
    int? id,
    List<MultipartFile>? files,
  }) async {
    try {
      final postTyreReplacementPictureUploadData = await restApi
          .postTyreReplacementPictureUpload(
            token: _getAuthHeader(),
            id: id,
            files: files,
          );

      if (postTyreReplacementPictureUploadData['IsSuccess'] == true) {
        getTyreReplacementData();
        return true;
      } else {
        print(
          'API call failed: ${postTyreReplacementPictureUploadData['Message']}',
        );
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
    }
  }

  Future<bool> postTyreReplacementPictureDelete({int? id}) async {
    try {
      final postTyreReplacementPictureDelete = await restApi
          .deleteTyreReplacementPictureDelete(token: _getAuthHeader(), id: id);

      if (postTyreReplacementPictureDelete['IsSuccess'] == true) {
        getTyreReplacementDetail();
        return true;
      } else {
        print(
          'API call failed: ${postTyreReplacementPictureDelete['Message']}',
        );
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
    }
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
