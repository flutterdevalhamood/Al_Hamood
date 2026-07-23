/// Models matching the payload returned by GET /api/getSalesDataBaseList
/// (products with their api_units, customers with their customer_prices
/// and vehicles, and the next available pad_number).

class ProductUnit {
  final int id;
  final String name;
  final int productId;

  ProductUnit({required this.id, required this.name, required this.productId});

  factory ProductUnit.fromJson(Map<String, dynamic> json) => ProductUnit(
    id: int.tryParse(json['id'].toString()) ?? 0,
    name: (json['Name'] ?? '').toString(),
    productId: int.tryParse(json['product_id'].toString()) ?? 0,
  );
}

class ProductItem {
  final int id;
  final String name;
  final List<ProductUnit> units;

  ProductItem({required this.id, required this.name, required this.units});

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final unitsJson = (json['api_units'] as List<dynamic>? ?? []);
    return ProductItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: (json['Name'] ?? '').toString(),
      units:
          unitsJson
              .map((e) => ProductUnit.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  @override
  String toString() => name;
}

class CustomerPriceInfo {
  final int id;
  final double rate;
  final double vat;
  final double customerLimit;

  CustomerPriceInfo({
    required this.id,
    required this.rate,
    required this.vat,
    required this.customerLimit,
  });

  factory CustomerPriceInfo.fromJson(Map<String, dynamic> json) =>
      CustomerPriceInfo(
        id: int.tryParse(json['id'].toString()) ?? 0,
        rate: double.tryParse(json['Rate'].toString()) ?? 0,
        vat: double.tryParse(json['VAT'].toString()) ?? 0,
        customerLimit: double.tryParse(json['customerLimit'].toString()) ?? 0,
      );
}

class CustomerVehicleInfo {
  final int id;
  final String registrationNumber;

  CustomerVehicleInfo({required this.id, required this.registrationNumber});

  factory CustomerVehicleInfo.fromJson(Map<String, dynamic> json) =>
      CustomerVehicleInfo(
        id: int.tryParse(json['id'].toString()) ?? 0,
        registrationNumber: (json['registrationNumber'] ?? '').toString(),
      );

  @override
  String toString() => registrationNumber;
}

class CustomerItem {
  final int id;
  final String name;
  final List<CustomerPriceInfo> prices;
  final List<CustomerVehicleInfo> vehicles;

  CustomerItem({
    required this.id,
    required this.name,
    required this.prices,
    required this.vehicles,
  });

  double get defaultRate => prices.isNotEmpty ? prices.first.rate : 0;
  double get defaultVat => prices.isNotEmpty ? prices.first.vat : 0;
  double get creditLimit => prices.isNotEmpty ? prices.first.customerLimit : 0;

  factory CustomerItem.fromJson(Map<String, dynamic> json) {
    final pricesJson = (json['customer_prices'] as List<dynamic>? ?? []);
    final vehiclesJson = (json['vehicles'] as List<dynamic>? ?? []);
    return CustomerItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: (json['Name'] ?? '').toString(),
      prices:
          pricesJson
              .map((e) => CustomerPriceInfo.fromJson(e as Map<String, dynamic>))
              .toList(),
      vehicles:
          vehiclesJson
              .map(
                (e) => CustomerVehicleInfo.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  @override
  String toString() => name;
}

class PadNumberInfo {
  final int padNo;
  final DateTime? lastDate;

  PadNumberInfo({required this.padNo, this.lastDate});

  factory PadNumberInfo.fromJson(Map<String, dynamic> json) => PadNumberInfo(
    padNo: int.tryParse(json['pad_no'].toString()) ?? 0,
    lastDate:
        json['last_date'] != null
            ? DateTime.tryParse(json['last_date'].toString())
            : null,
  );
}

class SaleBaseData {
  final PadNumberInfo? padNumber;
  final List<ProductItem> products;
  final List<CustomerItem> customers;

  SaleBaseData({
    this.padNumber,
    required this.products,
    required this.customers,
  });

  factory SaleBaseData.fromJson(Map<String, dynamic> json) {
    final data = (json['Data'] ?? {}) as Map<String, dynamic>;
    final productsJson = (data['products'] as List<dynamic>? ?? []);
    final customersJson = (data['customer'] as List<dynamic>? ?? []);
    return SaleBaseData(
      padNumber:
          data['pad_number'] != null
              ? PadNumberInfo.fromJson(
                data['pad_number'] as Map<String, dynamic>,
              )
              : null,
      products:
          productsJson
              .map((e) => ProductItem.fromJson(e as Map<String, dynamic>))
              .toList(),
      customers:
          customersJson
              .map((e) => CustomerItem.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}
