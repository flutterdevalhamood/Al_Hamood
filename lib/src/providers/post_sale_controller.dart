import 'package:flutter/material.dart';
import 'package:sample/src/models/sale_base_model.dart';

import '../data/rest_client.dart';
import '../models/sale_row_item.dart';
import '../repo/auth_repo.dart';

/// A row in the bottom "already saved" summary table (Pad # | Customer |
/// Vehicle | Quantity | Unit Price | Amount | Paid | Time), populated
/// once a batch of grid rows has been posted in this session.
class SaleBatchSummary {
  SaleBatchSummary({
    required this.padNumber,
    required this.customerName,
    required this.vehicleReg,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    required this.paid,
    required this.time,
  });

  final String padNumber;
  final String customerName;
  final String vehicleReg;
  final double quantity;
  final double unitPrice;
  final double amount;
  final double paid;
  final DateTime time;
}

class PostSaleController with ChangeNotifier {
  /// The id of the employee posting this sale, if your backend tracks
  /// it — it's optional, so it's fine to leave this null.
  PostSaleController({this.employeeId});

  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  SaleBaseData? baseData;

  /// Editable grid rows (top table).
  final List<SaleRowItem> rows = [];

  /// Batches saved during this session (bottom table).
  final List<SaleBatchSummary> savedBatches = [];

  // Header-level fields the whole sale is posted under.
  CustomerItem? headerCustomer;
  int? employeeId;
  DateTime saleDate = DateTime.now();
  String referenceNumber = '';
  String termsAndCondition = '';
  String supplierNote = '';

  double cashPaid = 0;
  double accountClosing = 0;

  Future<bool> _checkToken() async {
    final token = AuthRepo.token;

    if (token == null || token.isEmpty) {
      debugPrint('No token available - auth failed');
      AuthRepo.handleAuthError();
      return false;
    }

    if (AuthRepo.isTokenExpired()) {
      debugPrint('Token expired - auth failed');
      AuthRepo.handleAuthError();
      return false;
    }

    return true;
  }

  String _getAuthHeader() => 'Bearer ${AuthRepo.token}';

  /// Loads products, customers (with prices/vehicles) and the next pad
  /// number from GET /api/getSalesDataBaseList.
  Future<void> loadBaseData() async {
    if (!await _checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await restApi.getSalesDataBaseList(
        token: _getAuthHeader(),
      );

      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        baseData = SaleBaseData.fromJson(response);
        if (rows.isEmpty) addRow();
      } else if (response is Map<String, dynamic>) {
        errorMessage = response['Message']?.toString() ?? 'Failed to load data';
        debugPrint('getSalesDataBaseList failed: $errorMessage');
      } else {
        errorMessage = 'Unexpected API response format';
      }
    } catch (e) {
      debugPrint('Error loading base data: $e');
      errorMessage = 'Error: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------
  // Row management
  // ---------------------------------------------------------------------

  String addRow() {
    final row = SaleRowItem();
    row.padNumber = baseData?.padNumber?.padNo.toString() ?? '';
    rows.add(row);
    notifyListeners();
    return row.id;
  }

  void removeRow(String id) {
    rows.removeWhere((r) => r.id == id);
    if (rows.isEmpty) addRow();
    notifyListeners();
  }

  /// Public lookup used by the line-item editor bottom sheet.
  SaleRowItem? rowById(String id) => _rowById(id);

  SaleRowItem? _rowById(String id) {
    for (final r in rows) {
      if (r.id == id) return r;
    }
    return null;
  }

  void setRowProduct(String id, ProductItem? product) {
    final row = _rowById(id);
    if (row == null) return;
    row.product = product;
    row.unit =
        (product != null && product.units.isNotEmpty)
            ? product.units.first
            : null;
    notifyListeners();
  }

  void setRowUnit(String id, ProductUnit? unit) {
    final row = _rowById(id);
    if (row == null) return;
    row.unit = unit;
    notifyListeners();
  }

  void setRowDate(String id, DateTime date) {
    final row = _rowById(id);
    if (row == null) return;
    row.date = date;
    notifyListeners();
  }

  void setRowPadNumber(String id, String padNumber) {
    final row = _rowById(id);
    if (row == null) return;
    row.padNumber = padNumber;
    notifyListeners();
  }

  /// Selecting a customer auto-fills unit price + VAT from
  /// `customer_prices`, resets the vehicle, and narrows the vehicle
  /// dropdown to that customer's fleet.
  void setRowCustomer(String id, CustomerItem? customer) {
    final row = _rowById(id);
    if (row == null) return;
    row.customer = customer;
    row.vehicle = null;
    if (customer != null) {
      row.unitPrice = customer.defaultRate;
      row.vat = customer.defaultVat;
    }
    notifyListeners();
  }

  void setRowVehicle(String id, CustomerVehicleInfo? vehicle) {
    final row = _rowById(id);
    if (row == null) return;
    row.vehicle = vehicle;
    notifyListeners();
  }

  void setRowQuantity(String id, double quantity) {
    final row = _rowById(id);
    if (row == null) return;
    row.quantity = quantity;
    notifyListeners();
  }

  void setRowUnitPrice(String id, double price) {
    final row = _rowById(id);
    if (row == null) return;
    row.unitPrice = price;
    notifyListeners();
  }

  void setRowVat(String id, double vat) {
    final row = _rowById(id);
    if (row == null) return;
    row.vat = vat;
    notifyListeners();
  }

  void setRowDescription(String id, String description) {
    final row = _rowById(id);
    if (row == null) return;
    row.description = description;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Totals (drive the Total Vat / Grand Total / Remaining Balance panel)
  // ---------------------------------------------------------------------

  double get subTotal => rows.fold(0.0, (sum, r) => sum + r.rowTotal);
  double get totalVat => rows.fold(0.0, (sum, r) => sum + r.rowVatAmount);
  double get grandTotal => subTotal + totalVat;
  double get remainingBalance => grandTotal - cashPaid;

  void setCashPaid(double value) {
    cashPaid = value;
    notifyListeners();
  }

  void setAccountClosing(double value) {
    accountClosing = value;
    notifyListeners();
  }

  void setEmployeeId(int? id) {
    employeeId = id;
    notifyListeners();
  }

  void setHeaderCustomer(CustomerItem? customer) {
    headerCustomer = customer;
    notifyListeners();
  }

  void setReferenceNumber(String value) {
    referenceNumber = value;
  }

  void setSaleDate(DateTime value) {
    saleDate = value;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------

  String get _formattedSaleDate =>
      '${saleDate.year.toString().padLeft(4, '0')}-'
      '${saleDate.month.toString().padLeft(2, '0')}-'
      '${saleDate.day.toString().padLeft(2, '0')}';

  /// POSTs the current grid to /api/Sales. On success the posted rows
  /// are moved into [savedBatches] (bottom table) and the grid resets
  /// to a single blank row.
  Future<bool> submit() async {
    if (!await _checkToken()) return false;

    final validRows = rows.where((r) => r.isValid).toList();
    if (validRows.isEmpty) {
      errorMessage = 'Add at least one complete line before saving';
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Sent as ONE json body (see rest_client_post_sale_snippet.dart's
      // @Body() Map<String, dynamic>? body). Note `sale_details` is the
      // actual List<Map> here — not jsonEncode()'d — so it reaches the
      // backend as a real JSON array, not a quoted string.
      final body = <String, dynamic>{
        'customer_id': headerCustomer?.id ?? validRows.first.customer?.id,
        'employee_id': employeeId,
        'SaleDate': _formattedSaleDate,
        'referenceNumber': referenceNumber,
        'Total': subTotal,
        'subTotal': subTotal,
        'totalVat': totalVat,
        'grandTotal': grandTotal,
        'paidBalance': cashPaid,
        'remainingBalance': remainingBalance,
        'TermsAndCondition': termsAndCondition,
        'supplierNote': supplierNote,
        'sale_details': validRows.map((r) => r.toJson()).toList(),
      };

      final response = await restApi.postSalesData(
        token: _getAuthHeader(),
        body: body,
      );

      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        final now = DateTime.now();
        for (final r in validRows) {
          savedBatches.add(
            SaleBatchSummary(
              padNumber: r.padNumber,
              customerName: r.customer?.name ?? '',
              vehicleReg: r.vehicle?.registrationNumber ?? '',
              quantity: r.quantity,
              unitPrice: r.unitPrice,
              amount: r.rowSubTotal,
              paid: cashPaid,
              time: now,
            ),
          );
        }
        rows.clear();
        cashPaid = 0;
        accountClosing = 0;
        addRow();
        return true;
      }

      errorMessage =
          response is Map<String, dynamic>
              ? (response['Message']?.toString() ?? 'Failed to save sale')
              : 'Unexpected API response format';
      debugPrint('postSalesData failed: $errorMessage');
      return false;
    } catch (e) {
      debugPrint('Error saving sale: $e');
      errorMessage = 'Error: ${e.toString()}';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void resetForm() {
    rows.clear();
    headerCustomer = null;
    referenceNumber = '';
    termsAndCondition = '';
    supplierNote = '';
    cashPaid = 0;
    accountClosing = 0;
    errorMessage = null;
    addRow();
    notifyListeners();
  }
}
