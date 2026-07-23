import 'package:flutter/foundation.dart';
import 'package:sample/src/models/sale_base_model.dart';

/// A single editable line in the Post Sale grid (the top table in the
/// mock-up: Product | Date | Pad # | Customer | Vehicle | Quantity |
/// Unit Price | VAT | Amount).
///
/// [toJson] produces exactly the shape the backend expects inside the
/// `sale_details` field, e.g.:
/// {"PadNumber":"192343","vehicle_id":1,"product_id":1,"unit_id":1,
///  "Price":20,"Quantity":4,"rowTotal":100,"VAT":5,"rowVatAmount":50,
///  "rowSubTotal":500.5,"Description":"test"}
class SaleRowItem {
  SaleRowItem({String? id}) : id = id ?? UniqueKey().toString();

  /// Local-only id used as a widget/list key, never sent to the server.
  final String id;

  ProductItem? product;
  ProductUnit? unit;
  DateTime date = DateTime.now();
  String padNumber = '';
  CustomerItem? customer;
  CustomerVehicleInfo? vehicle;

  double quantity = 0;
  double unitPrice = 0;
  double vat = 0; // percentage, e.g. 5 for 5%
  String description = '';

  double get rowTotal => quantity * unitPrice;
  double get rowVatAmount => rowTotal * vat / 100;
  double get rowSubTotal => rowTotal + rowVatAmount;

  bool get isValid =>
      product != null &&
      customer != null &&
      vehicle != null &&
      padNumber.trim().isNotEmpty &&
      quantity > 0 &&
      unitPrice >= 0;

  Map<String, dynamic> toJson() => {
    'PadNumber': padNumber,
    'vehicle_id': vehicle?.id,
    'product_id': product?.id,
    'unit_id': unit?.id,
    'Price': unitPrice,
    'Quantity': quantity,
    'rowTotal': rowTotal,
    'VAT': vat,
    'rowVatAmount': rowVatAmount,
    'rowSubTotal': rowSubTotal,
    'Description': description,
  };
}
