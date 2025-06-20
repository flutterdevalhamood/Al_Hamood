import 'dart:convert';

class VehicleTyreResponse {
  final int statusCode;
  final String message;
  final bool isSuccess;
  final List<VehicleTyreData> data;

  VehicleTyreResponse({
    required this.statusCode,
    required this.message,
    required this.isSuccess,
    required this.data,
  });

  factory VehicleTyreResponse.fromJson(Map<String, dynamic> json) {
    return VehicleTyreResponse(
      statusCode: json['StatusCode'] ?? 0,
      message: json['Message'] ?? '',
      isSuccess: json['IsSuccess'] ?? false,
      data:
          (json['Data'] as List<dynamic>?)
              ?.map((item) => VehicleTyreData.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'StatusCode': statusCode,
      'Message': message,
      'IsSuccess': isSuccess,
      'Data': data.map((item) => item.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

class VehicleTyreData {
  final int id;
  final String companyVehicleId;
  final String vehicleTyreCodeId;
  final String brand;
  final String tyreChangeDate;
  final CompanyVehicle companyVehicle;
  final TyreCode code;

  VehicleTyreData({
    required this.id,
    required this.companyVehicleId,
    required this.vehicleTyreCodeId,
    required this.brand,
    required this.tyreChangeDate,
    required this.companyVehicle,
    required this.code,
  });

  factory VehicleTyreData.fromJson(Map<String, dynamic> json) {
    return VehicleTyreData(
      id: json['id'] ?? 0,
      companyVehicleId: json['company_vehicle_id'] ?? '',
      vehicleTyreCodeId: json['vehicle_tyre_code_id'] ?? '',
      brand: json['brand'] ?? '',
      tyreChangeDate: json['tyre_change_date'] ?? '',
      companyVehicle: CompanyVehicle.fromJson(json['company_vehicle'] ?? {}),
      code: TyreCode.fromJson(json['code'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_vehicle_id': companyVehicleId,
      'vehicle_tyre_code_id': vehicleTyreCodeId,
      'brand': brand,
      'tyre_change_date': tyreChangeDate,
      'company_vehicle': companyVehicle.toJson(),
      'code': code.toJson(),
    };
  }
}

class CompanyVehicle {
  final int id;
  final String plateNo1;

  CompanyVehicle({required this.id, required this.plateNo1});

  factory CompanyVehicle.fromJson(Map<String, dynamic> json) {
    return CompanyVehicle(
      id: json['id'] ?? 0,
      plateNo1: json['PlateNo1'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'PlateNo1': plateNo1};
  }
}

class TyreCode {
  final int id;
  final String code;

  TyreCode({required this.id, required this.code});

  factory TyreCode.fromJson(Map<String, dynamic> json) {
    return TyreCode(id: json['id'] ?? 0, code: json['Code'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'Code': code};
  }
}
