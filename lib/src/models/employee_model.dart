/// Employee model returned by `GET /api/Attendance/GetBaseList`.
///
/// Kept as its own small, immutable class instead of passing raw
/// `Map<String, dynamic>` around everywhere. Benefits:
///  - Screens / widgets never need to know the API's exact key casing
///    (`Name` vs `name`, `photo` vs `Photo`) — that's isolated to
///    [Employee.fromMap].
///  - Adding a field later (designation, department, badge number, ...)
///    only touches this file, not every widget that reads a raw map.
///  - `matches()` centralizes search behaviour so the UI stays dumb.
class Employee {
  final int id;
  final String name;
  final String? photoUrl;

  /// `true` if this employee has already checked in today (and has not
  /// yet checked out) per `GetBaseList`'s `status` field. Drives whether
  /// AttendanceScreen shows "Check In" or "Check Out" for them.
  final bool status;

  const Employee({
    required this.id,
    required this.name,
    this.photoUrl,
    this.status = false,
  });

  factory Employee.fromMap(Map<String, dynamic> map) {
    final rawPhoto = map['photo'];
    final photo =
        (rawPhoto is String && rawPhoto.trim().isNotEmpty)
            ? rawPhoto.trim()
            : null;

    final rawId = map['id'];
    final id = rawId is int ? rawId : int.tryParse('$rawId') ?? -1;

    return Employee(
      id: id,
      name:
          (map['Name'] as String?)?.trim().isNotEmpty == true
              ? (map['Name'] as String).trim()
              : 'Unnamed employee',
      photoUrl: photo,
      status: map['status'] == true,
    );
  }

  bool get hasPhoto => photoUrl != null;

  /// `true` when this employee is due to check out rather than check in.
  bool get isCheckedIn => status;

  /// Case-insensitive match on either the display name or the numeric id —
  /// used by the picker's search field.
  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    return name.toLowerCase().contains(q) || id.toString().contains(q);
  }

  @override
  bool operator ==(Object other) => other is Employee && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
