import 'package:flutter/material.dart';
import 'package:sample/src/models/sale_model.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class SalesController with ChangeNotifier {
  bool isLoading = false;
  int currentPage = 1;
  final int limit = 10;
  bool hasMore = true;
  String? errorMessage;

  List<Sale>? salesOriginalData;
  List<Sale>? salesData; // filtered/displayed list

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  int get filteredCount => salesData?.length ?? 0;
  int get totalCount => salesOriginalData?.length ?? 0;
  bool get isFiltered => _searchQuery.isNotEmpty;

  // Currently opened sale (for the detail screen)
  Sale? selectedSale;

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

  String _getAuthHeader() => 'Bearer ${AuthRepo.token}';

  /// Loads a page of sales from GET /api/Sales/paginate/{page}/{limit}
  Future<void> getSalesData({bool loadMore = false}) async {
    if (!await _checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await restApi.getSalesData(
        currentPage,
        limit,
        _getAuthHeader(),
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          final data = response['Data'] as List<dynamic>?;

          if (data != null) {
            final newSales =
                data
                    .map((e) => Sale.fromJson(e as Map<String, dynamic>))
                    .toList();

            if (loadMore) {
              salesOriginalData ??= [];
              salesOriginalData!.addAll(newSales);
            } else {
              salesOriginalData = List.from(newSales);
              currentPage = 1;
            }

            hasMore = data.length == limit;

            if (_searchQuery.isNotEmpty) {
              _applySearchFilter();
            } else {
              salesData = List.from(salesOriginalData!);
            }
          } else {
            hasMore = false;
            if (!loadMore) {
              salesOriginalData = [];
              salesData = [];
            }
          }
        } else {
          errorMessage = response['Message'] ?? 'API call failed';
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
      getSalesData(loadMore: true);
    }
  }

  Future<void> refreshData() async {
    currentPage = 1;
    hasMore = true;
    await getSalesData();
  }

  /// The web version searches "by Pad No" — pad numbers live on the
  /// sale_details[] line items, so we match against any of a sale's
  /// pad numbers as well as its SaleNumber.
  void searchSales(String query) {
    _searchQuery = query.trim();
    _applySearchFilter();
    notifyListeners();
  }

  void _applySearchFilter() {
    if (salesOriginalData == null) return;

    if (_searchQuery.isEmpty) {
      salesData = List.from(salesOriginalData!);
      return;
    }

    final query = _searchQuery.toLowerCase();
    salesData =
        salesOriginalData!.where((sale) {
          final matchesSaleNumber = sale.saleNumber.toLowerCase().contains(
            query,
          );
          final matchesPad = sale.saleDetails.any(
            (d) => d.padNumber.toLowerCase().contains(query),
          );
          return matchesSaleNumber || matchesPad;
        }).toList();
  }

  void clearSearch() {
    _searchQuery = '';
    if (salesOriginalData != null) {
      salesData = List.from(salesOriginalData!);
    }
    notifyListeners();
  }

  void selectSale(Sale sale) {
    selectedSale = sale;
    notifyListeners();
  }

  void clearSelectedSale() {
    selectedSale = null;
    notifyListeners();
  }

  void clearData() {
    salesData = null;
    salesOriginalData = null;
    currentPage = 1;
    hasMore = true;
    errorMessage = null;
    _searchQuery = '';
    notifyListeners();
  }

  dynamic _handleApiError(dynamic e) {
    debugPrint("Error: $e");
    errorMessage = 'Error: ${e.toString()}';
    return false;
  }
}
