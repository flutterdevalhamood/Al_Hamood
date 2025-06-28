import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class SwapTyreController with ChangeNotifier {
  bool isLoading = false;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;
  List<Map<String, dynamic>>? swapTyreData;
  List<Map<String, dynamic>>? swapTyreOriginalData;
  List<Map<String, dynamic>>? swapTyreVersion;
  List<Map<String, dynamic>>? companyVehicleData;
  List<Map<String, dynamic>>? swapTyreReplacementData;
  List<Map<String, dynamic>>? swapTyreCodesOfVersionData;
  String? reportUrl;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  int get filteredCount => swapTyreReplacementData?.length ?? 0;
  int get totalCount => swapTyreOriginalData?.length ?? 0;
  bool get isFiltered => _searchQuery.isNotEmpty;

  int? selectedVehicleId;
  int? selectedVersionId;
  int? selectedTyreCodeId;
  int? selectedSupplierId;

  bool _isLoadingTyreVersions = false;
  bool get isLoadingTyreVersions => _isLoadingTyreVersions;

  int? _swapTyreId;

  int? get swapTyreId => _swapTyreId;

  void setSwapTyreId(int id) {
    _swapTyreId = id;
    // Clear previous detail data when setting new ID
    swapTyreData = null;
    errorMessage = null;
  }

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

  Future<void> getSwapTyreData({bool loadMore = false}) async {
    if (!await _checkToken()) return;

    isLoading = true;
    errorMessage = null; // Clear previous errors
    notifyListeners();

    try {
      final swapTyreData = await restApi.getSwapTyre(
        currentPage,
        totalPages,
        _getAuthHeader(),
      );

      if (swapTyreData is Map<String, dynamic>) {
        if (swapTyreData['IsSuccess'] == true) {
          final data = swapTyreData['Data'] as List<dynamic>?;
          if (data != null) {
            final newSwapTyreData =
                data.map((v) => v as Map<String, dynamic>).toList();

            if (loadMore) {
              swapTyreOriginalData ??= [];
              swapTyreOriginalData!.addAll(newSwapTyreData);
              swapTyreReplacementData ??= [];
              swapTyreReplacementData!.addAll(newSwapTyreData);
            } else {
              swapTyreOriginalData = List.from(newSwapTyreData);
              swapTyreReplacementData = List.from(newSwapTyreData);
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
              swapTyreReplacementData = [];
              swapTyreOriginalData = [];
            }
          }
        } else {
          errorMessage = swapTyreData['Message'] ?? 'API call failed';
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
      getSwapTyreData(loadMore: true);
    }
  }

  void searchSwapTyre(String query) {
    _searchQuery = query.trim();
    _applySearchFilter();
    notifyListeners();
  }

  void _applySearchFilter() {
    if (swapTyreOriginalData == null) return;

    if (_searchQuery.isEmpty) {
      swapTyreReplacementData = List.from(swapTyreOriginalData!);
    } else {
      final query = _searchQuery.toLowerCase();
      swapTyreReplacementData =
          swapTyreOriginalData!.where((item) {
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
    if (swapTyreOriginalData != null) {
      swapTyreReplacementData = List.from(swapTyreOriginalData!);
    }
    notifyListeners();
  }

  Future<void> refreshData() async {
    currentPage = 1;
    hasMore = true;
    await getSwapTyreData();
  }

  void clearData() {
    selectedVehicleId = null;
    selectedVersionId = null;
    selectedTyreCodeId = null;
    selectedSupplierId = null;
    swapTyreReplacementData = null;
    swapTyreOriginalData = null;
    currentPage = 1;
    hasMore = true;
    errorMessage = null;
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> getSwapTyreDetail() async {
    if (!await _checkToken()) return;

    if (_swapTyreId == null) {
      errorMessage = "Swap Tyre ID is required";
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final tyreSwapTyreDetailData = await restApi.getSwapTyreDetail(
        id: _swapTyreId,
        token: _getAuthHeader(),
      );

      if (tyreSwapTyreDetailData['IsSuccess'] == true) {
        final data = tyreSwapTyreDetailData['Data'] as Map<String, dynamic>;
        swapTyreData = [data];
        debugPrint('Assigned units fetched: ${swapTyreData?.length}');
      } else {
        errorMessage =
            tyreSwapTyreDetailData['Message'] ??
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

  void clearDetailData() {
    _swapTyreId = null;
    swapTyreData = null;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> getSwapTyreBaseData() async {
    if (!await _checkToken()) return;

    isLoading = true;
    notifyListeners();

    try {
      final swapTyreBaseData = await restApi.getSwapTyreBaseList(
        token: _getAuthHeader(),
      );

      if (swapTyreBaseData['IsSuccess'] == true) {
        swapTyreVersion = List<Map<String, dynamic>>.from(
          swapTyreBaseData['Data']['tyre_version'],
        );
        companyVehicleData = List<Map<String, dynamic>>.from(
          swapTyreBaseData['Data']['company_vehicles'],
        );
        debugPrint('Base data fetched successfully');
      } else {
        debugPrint('API call failed: ${swapTyreBaseData['Message']}');
        errorMessage =
            swapTyreBaseData['Message'] ?? 'Failed to fetch base data';
      }
    } catch (e) {
      _handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postSwapTyre({
    int? fromCompanyVehicleId,
    int? fromVehicleTyreCodeId,
    String? fromTyreDepthMm,
    String? fromTyreCondition,
    String? fromVehicleOdometer, //add
    List<MultipartFile>? fromVehicleOdometerImage, //add
    int? toCompanyVehicleId,
    int? toVehicleTyreCodeId,
    String? toTyreDepthMm, //add
    String? toTyreCondition,
    String? toVehicleOdometer,
    List<MultipartFile>? toVehicleOdometerImage, //add
    String? tyreChangeDate,
    String? reasonForChange,
    String? changedBy,
  }) async {
    if (!await _checkToken()) return false;

    try {
      final response = await restApi.postSwapTyre(
        token: _getAuthHeader(),
        fromCompanyVehicleId: fromCompanyVehicleId,
        fromVehicleTyreCodeId: fromVehicleTyreCodeId,
        fromTyreDepthMm: fromTyreDepthMm,
        fromTyreCondition: fromTyreCondition,
        fromVehicleOdometer: fromVehicleOdometer,
        fromVehicleOdometerImage: fromVehicleOdometerImage,
        toCompanyVehicleId: toCompanyVehicleId,
        toVehicleTyreCodeId: toVehicleTyreCodeId,
        toTyreDepthMm: toTyreDepthMm,
        toTyreCondition: toTyreCondition,
        toVehicleOdometer: toVehicleOdometer,
        toVehicleOdometerImage: toVehicleOdometerImage,
        tyreChangeDate: tyreChangeDate,
        reasonForChange: reasonForChange,
        changedBy: changedBy,
      );

      // Check response
      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        // lastCreatedTyreReplacementId =
        //     response['Data']?['Id'] ?? response['Id'];
        getSwapTyreData();
        NavigationService().pushNavigation(Screenroutes.swapTyreListScreen);
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

  Future<void> getSwapTyreCodesOfVersion(int selectedVersionId) async {
    if (!await _checkToken()) return;

    _isLoadingTyreVersions = true;
    swapTyreCodesOfVersionData = null;
    notifyListeners();

    try {
      final swapTyreCodeOfVersionResponse = await restApi
          .getSwapTyreCodeOfVersion(
            id: selectedVersionId,
            token: _getAuthHeader(),
          );

      if (swapTyreCodeOfVersionResponse['IsSuccess'] == true) {
        final swapTyreCodesData = List<Map<String, dynamic>>.from(
          swapTyreCodeOfVersionResponse['Data'] ?? [],
        );

        swapTyreCodesOfVersionData =
            swapTyreCodesData.map((item) {
              return {
                'id': item['id'].toString(),
                'Code': item['Code'],
                'display_name': item['Code'], // Use Code for display
              };
            }).toList();

        debugPrint(
          'Tyre version data fetched successfully: ${swapTyreCodesOfVersionData?.length} invoices',
        );
        debugPrint('Tyre versions: ${swapTyreCodesData.join(', ')}');
      } else {
        debugPrint(
          'API call failed: ${swapTyreCodeOfVersionResponse['Message']}',
        );
        // Don't set main errorMessage here to avoid affecting main screen
        swapTyreCodesOfVersionData = []; // Set empty list on failure
      }
    } catch (e) {
      debugPrint('Error fetching invoices: $e');
      swapTyreCodesOfVersionData = []; // Set empty list on error
      // Don't call _handleApiError here as it might affect main loading state
    } finally {
      _isLoadingTyreVersions = false;
      notifyListeners();
    }
  }

  void clearCodesOfVersion() {
    swapTyreCodesOfVersionData = null;
    notifyListeners();
  }

  Future<void> deleteSwapTyreData(int? id, String? descriptionText) async {
    if (!await _checkToken()) return;

    try {
      await restApi.deleteSwapTyreData(
        token: _getAuthHeader(),
        id: id,
        description: descriptionText,
      );
      await getSwapTyreData();
    } catch (e) {
      _handleApiError(e);
    }
  }

  Future<bool> postSwapTyrePictureUpload({
    int? id,
    List<MultipartFile>? files,
  }) async {
    try {
      final postSwapTyrePictureUploadData = await restApi
          .postSwapTyrePictureUpload(
            token: _getAuthHeader(),
            id: id,
            files: files,
          );

      if (postSwapTyrePictureUploadData['IsSuccess'] == true) {
        getSwapTyreData();
        return true;
      } else {
        print('API call failed: ${postSwapTyrePictureUploadData['Message']}');
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
    }
  }

  Future<bool> postSwapTyrePictureDelete({int? id}) async {
    try {
      final postSwapTyrePictureDelete = await restApi.deleteSwapTyreData(
        token: _getAuthHeader(),
        id: id,
      );

      if (postSwapTyrePictureDelete['IsSuccess'] == true) {
        getSwapTyreDetail();
        return true;
      } else {
        print('API call failed: ${postSwapTyrePictureDelete['Message']}');
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
