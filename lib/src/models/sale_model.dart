// Models for the Sales list & detail feature.
// Mirrors the shape of GET /api/Sales/paginate/{page}/{limit}

num _toNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}

String _toStr(dynamic v) => v?.toString() ?? '';

bool _toBool(dynamic v) {
  final s = _toStr(v);
  return s == '1' || s.toLowerCase() == 'true';
}

/// api_user block — the app user who created the sale
class SaleApiUser {
  final int id;
  final String name;
  final String email;
  final String? contactNumber;
  final String address;
  final String companyId;

  SaleApiUser({
    required this.id,
    required this.name,
    required this.email,
    this.contactNumber,
    required this.address,
    required this.companyId,
  });

  factory SaleApiUser.fromJson(Map<String, dynamic> json) {
    return SaleApiUser(
      id: _toNum(json['id']).toInt(),
      name: _toStr(json['name']),
      email: _toStr(json['email']),
      contactNumber: json['contactNumber']?.toString(),
      address: _toStr(json['address']),
      companyId: _toStr(json['company_id']),
    );
  }
}

/// api_customer block — full customer profile
class SaleCustomer {
  final int id;
  final String name;
  final String representative;
  final num openingBalance;
  final String trnNumber;
  final String? phone;
  final String? mobile;
  final String? email;
  final String address;
  final String registrationDate;
  final String? trnCertificate;
  final String? trnCertificateExpiryDate;
  final String loginEmail;
  final bool isActive;

  SaleCustomer({
    required this.id,
    required this.name,
    required this.representative,
    required this.openingBalance,
    required this.trnNumber,
    this.phone,
    this.mobile,
    this.email,
    required this.address,
    required this.registrationDate,
    this.trnCertificate,
    this.trnCertificateExpiryDate,
    required this.loginEmail,
    required this.isActive,
  });

  factory SaleCustomer.fromJson(Map<String, dynamic> json) {
    return SaleCustomer(
      id: _toNum(json['id']).toInt(),
      name: _toStr(json['Name']),
      representative: _toStr(json['Representative']),
      openingBalance: _toNum(json['openingBalance']),
      trnNumber: _toStr(json['TRNNumber']),
      phone: json['Phone']?.toString(),
      mobile: json['Mobile']?.toString(),
      email: json['Email']?.toString(),
      address: _toStr(json['Address']),
      registrationDate: _toStr(json['registrationDate']),
      trnCertificate: json['trn_certificate']?.toString(),
      trnCertificateExpiryDate: json['trn_certificate_expiry_date']?.toString(),
      loginEmail: _toStr(json['login_email']),
      isActive: _toBool(json['isActive']),
    );
  }
}

/// api_units entries under api_product
class SaleUnit {
  final int id;
  final String name;

  SaleUnit({required this.id, required this.name});

  factory SaleUnit.fromJson(Map<String, dynamic> json) {
    return SaleUnit(id: _toNum(json['id']).toInt(), name: _toStr(json['Name']));
  }
}

/// api_product block inside a sale_detail
class SaleProduct {
  final int id;
  final String name;
  final String? description;
  final List<SaleUnit> units;

  SaleProduct({
    required this.id,
    required this.name,
    this.description,
    required this.units,
  });

  factory SaleProduct.fromJson(Map<String, dynamic> json) {
    return SaleProduct(
      id: _toNum(json['id']).toInt(),
      name: _toStr(json['Name']),
      description: json['Description']?.toString(),
      units:
          (json['api_units'] as List<dynamic>? ?? [])
              .map((e) => SaleUnit.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

/// api_vehicle block inside a sale_detail
class SaleVehicle {
  final int id;
  final String registrationNumber;
  final String? description;

  SaleVehicle({
    required this.id,
    required this.registrationNumber,
    this.description,
  });

  factory SaleVehicle.fromJson(Map<String, dynamic> json) {
    return SaleVehicle(
      id: _toNum(json['id']).toInt(),
      registrationNumber: _toStr(json['registrationNumber']),
      description: json['Description']?.toString(),
    );
  }
}

/// A single line item under a sale (sale_details[])
class SaleDetail {
  final int id;
  final String padNumber;
  final String? description;
  final num quantity;
  final num price;
  final num rowTotal;
  final num vat;
  final num rowVatAmount;
  final num rowSubTotal;
  final SaleProduct? product;
  final SaleVehicle? vehicle;

  SaleDetail({
    required this.id,
    required this.padNumber,
    this.description,
    required this.quantity,
    required this.price,
    required this.rowTotal,
    required this.vat,
    required this.rowVatAmount,
    required this.rowSubTotal,
    this.product,
    this.vehicle,
  });

  factory SaleDetail.fromJson(Map<String, dynamic> json) {
    return SaleDetail(
      id: _toNum(json['id']).toInt(),
      padNumber: _toStr(json['PadNumber']),
      description: json['Description']?.toString(),
      quantity: _toNum(json['Quantity']),
      price: _toNum(json['Price']),
      rowTotal: _toNum(json['rowTotal']),
      vat: _toNum(json['VAT']),
      rowVatAmount: _toNum(json['rowVatAmount']),
      rowSubTotal: _toNum(json['rowSubTotal']),
      product:
          json['api_product'] != null
              ? SaleProduct.fromJson(
                json['api_product'] as Map<String, dynamic>,
              )
              : null,
      vehicle:
          json['api_vehicle'] != null
              ? SaleVehicle.fromJson(
                json['api_vehicle'] as Map<String, dynamic>,
              )
              : null,
    );
  }
}

/// A single Sale record (one entry in Data[])
class Sale {
  final int id;
  final String saleNumber;
  final String saleDate;
  final num total;
  final num subTotal;
  final num totalVat;
  final num grandTotal;
  final num paidBalance;
  final num remainingBalance;
  final String? description;
  final bool isPaid;
  final bool isPartialPaid;
  final String updatedAt;
  final SaleApiUser? apiUser;
  final SaleCustomer? customer;
  final List<SaleDetail> saleDetails;

  Sale({
    required this.id,
    required this.saleNumber,
    required this.saleDate,
    required this.total,
    required this.subTotal,
    required this.totalVat,
    required this.grandTotal,
    required this.paidBalance,
    required this.remainingBalance,
    this.description,
    required this.isPaid,
    required this.isPartialPaid,
    required this.updatedAt,
    this.apiUser,
    this.customer,
    required this.saleDetails,
  });

  /// Convenience: first line item, used to populate the summary row
  /// shown in the list (matches the web grid, which shows one Pad #
  /// and Vehicle per sale row).
  SaleDetail? get primaryDetail =>
      saleDetails.isNotEmpty ? saleDetails.first : null;

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: _toNum(json['id']).toInt(),
      saleNumber: _toStr(json['SaleNumber']),
      saleDate: _toStr(json['SaleDate']),
      total: _toNum(json['Total']),
      subTotal: _toNum(json['subTotal']),
      totalVat: _toNum(json['totalVat']),
      grandTotal: _toNum(json['grandTotal']),
      paidBalance: _toNum(json['paidBalance']),
      remainingBalance: _toNum(json['remainingBalance']),
      description: json['Description']?.toString(),
      isPaid: _toBool(json['IsPaid']),
      isPartialPaid: _toBool(json['IsPartialPaid']),
      updatedAt: _toStr(json['updated_at']),
      apiUser:
          json['api_user'] != null
              ? SaleApiUser.fromJson(json['api_user'] as Map<String, dynamic>)
              : null,
      customer:
          json['api_customer'] != null
              ? SaleCustomer.fromJson(
                json['api_customer'] as Map<String, dynamic>,
              )
              : null,
      saleDetails:
          (json['sale_details'] as List<dynamic>? ?? [])
              .map((e) => SaleDetail.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}
