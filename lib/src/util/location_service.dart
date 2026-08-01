import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum LocationWarmUpResult {
  success,
  serviceDisabled, // GPS/location toggle is off
  permissionDenied, // user hasn't granted it (yet)
  permissionDeniedForever, // user denied + checked "don't ask again"
  error,
}

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Position? cachedPosition;
  bool permissionGranted = false;
  bool serviceEnabled = false;

  Future<LocationWarmUpResult> warmUp() async {
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationWarmUpResult.serviceDisabled;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        permissionGranted = false;
        return LocationWarmUpResult.permissionDeniedForever;
      }

      permissionGranted =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      if (!permissionGranted) {
        return LocationWarmUpResult.permissionDenied;
      }

      cachedPosition ??= await Geolocator.getLastKnownPosition();

      final fresh = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      ).timeout(const Duration(seconds: 11));

      cachedPosition = fresh;
      return LocationWarmUpResult.success;
    } catch (_) {
      return LocationWarmUpResult.error;
    }
  }

  void clear() {
    cachedPosition = null;
    permissionGranted = false;
    serviceEnabled = false;
  }
}
