/// Model for a single employee, as returned inside `Data.employees`
/// by GET /api/Attendance/GetBaseList
class Employee {
  final int id;
  final String name;

  Employee({required this.id, required this.name});

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int,
      name: (json['Name'] as String? ?? '').trim(),
    );
  }

  @override
  bool operator ==(Object other) => other is Employee && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Wraps the full GetBaseList response:
/// { StatusCode, Message, IsSuccess, Data: { employees: [...] } }
class BaseListResponse {
  final int statusCode;
  final String message;
  final bool isSuccess;
  final List<Employee> employees;

  BaseListResponse({
    required this.statusCode,
    required this.message,
    required this.isSuccess,
    required this.employees,
  });

  /// [json] can be a Map (already decoded) or the raw dynamic body
  /// returned by the retrofit client — handles both.
  factory BaseListResponse.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    final data = map['Data'] as Map<String, dynamic>? ?? const {};
    final rawList = data['employees'] as List<dynamic>? ?? const [];

    return BaseListResponse(
      statusCode: map['StatusCode'] as int? ?? 0,
      message: map['Message'] as String? ?? '',
      isSuccess: map['IsSuccess'] as bool? ?? false,
      employees:
          rawList
              .map((e) => Employee.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}
