import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// App-wide singleton that owns the "warm" location fix.
///
/// DashboardScreen calls [warmUp] once, right after login/app-open. It
/// requests permission and grabs a low-accuracy fix in the background —
/// by the time the user navigates into AttendanceScreen, [cachedPosition]
/// is usually already populated, so that screen doesn't have to eat the
/// permission-dialog + first-GPS-fix latency itself.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Position? cachedPosition;
  bool permissionGranted = false;
  bool serviceEnabled = false;

  /// Fire-and-forget from DashboardScreen. Never throws — any failure here
  /// just means AttendanceScreen falls back to fetching on its own, same
  /// as it does today.
  Future<void> warmUp() async {
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      permissionGranted =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!permissionGranted) return;

      // Seed with whatever the OS already has cached, instantly.
      cachedPosition ??= await Geolocator.getLastKnownPosition();

      // Then get a fresh low-accuracy fix in the background. This is the
      // call that "warms up" the GPS/network provider so any subsequent
      // call (e.g. from AttendanceScreen) resolves much faster.
      final fresh = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      ).timeout(const Duration(seconds: 11));

      cachedPosition = fresh;
    } catch (_) {
      // Silent — Dashboard shouldn't ever show an error for this.
      // AttendanceScreen will retry properly with its own UI feedback.
    }
  }

  void clear() {
    cachedPosition = null;
    permissionGranted = false;
    serviceEnabled = false;
  }
}
