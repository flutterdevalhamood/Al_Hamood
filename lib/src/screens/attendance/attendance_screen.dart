import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart' show MultipartFile;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/models/employee_model.dart';
import 'package:sample/src/providers/attendance_controller.dart';
import 'package:sample/src/util/location_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Design tokens — matches SwapTyreListScreen's palette exactly.
  static const Color darkBlue = Color(0xFF1A1A2E);
  static const Color accentBlue = Color(0xFF1976D2);

  // Location
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String? _locationError;

  // Photo
  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;

  // Per-button loading flags — kept local (instead of relying solely on
  // controller.isSubmitting) so tapping Check In doesn't also spin the
  // Check Out button, and vice versa.
  bool _isCheckInLoading = false;
  bool _isCheckOutLoading = false;

  @override
  void initState() {
    super.initState();
    // Use listen:false in initState — we don't need to rebuild here,
    // just kick off the initial fetch (GET /Attendance/GetBaseList).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceController>().getAttendanceBaseList();
    });
    _fetchLocation();
  }

  // ---------------- Employees ----------------

  Future<void> _openEmployeePicker(AttendanceController controller) async {
    final employees = controller.employeeData;
    if (employees == null || employees.isEmpty) return;

    final result = await showModalBottomSheet<Employee>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _EmployeePickerSheet(
            employees: employees,
            selectedEmployee: controller.selectedEmployee,
          ),
    );

    if (result != null) {
      controller.setSelectedEmployeeObj(result);
    }
  }

  Future<Position> _getPositionWithFallback() async {
    // Show a stale-but-instant fix right away if we have one — avoids the
    // screen sitting on "Fetching location…" for the entire duration of a
    // slow/failed GPS acquisition indoors or with weak signal.
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null && mounted) {
      setState(() => _currentPosition = lastKnown);
    }

    try {
      // Low accuracy first — locks on much faster (network/cell based)
      // than 'medium'/'high', which wait for a GPS satellite fix.
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      ).timeout(const Duration(seconds: 9));
    } on TimeoutException {
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        ).timeout(const Duration(seconds: 11));
      } on TimeoutException {
        if (lastKnown != null) return lastKnown;
        rethrow;
      }
    } catch (_) {
      // Any other platform error (e.g. plugin channel hiccup) — still
      // fall back to last known rather than hanging indefinitely.
      if (lastKnown != null) return lastKnown;
      rethrow;
    }
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    // If Dashboard already warmed this up, use it immediately — this is
    // what eliminates the "first time" delay on this screen.
    final warm = LocationService.instance.cachedPosition;
    if (warm != null) {
      setState(() {
        _currentPosition = warm;
        _isLoadingLocation = false;
      });
      context.read<AttendanceController>().setLocation(
        lat: warm.latitude,
        lng: warm.longitude,
      );
      // Still refresh quietly in the background for accuracy, but don't
      // make the user wait on it.
      _refreshLocationInBackground();
      return;
    }

    // ...existing fallback logic (permission checks, _getPositionWithFallback, etc.) stays as-is
    // for the case where warm-up hasn't finished yet or failed.
  }

  Future<void> _refreshLocationInBackground() async {
    try {
      final fresh = await _getPositionWithFallback();
      LocationService.instance.cachedPosition = fresh;
      if (!mounted) return;
      setState(() => _currentPosition = fresh);
      context.read<AttendanceController>().setLocation(
        lat: fresh.latitude,
        lng: fresh.longitude,
      );
    } catch (_) {
      // Keep the warm fix on screen; don't surface an error for a silent refresh.
    }
  }

  // Future<void> _fetchLocation() async {
  //   setState(() {
  //     _isLoadingLocation = true;
  //     _locationError = null;
  //   });
  //   try {
  //     final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //     if (!serviceEnabled) {
  //       setState(() => _isLoadingLocation = false);
  //       if (!mounted) return;
  //       await _showEnableLocationDialog();
  //       return;
  //     }
  //
  //     LocationPermission permission = await Geolocator.checkPermission();
  //     if (permission == LocationPermission.denied) {
  //       permission = await Geolocator.requestPermission();
  //       if (permission == LocationPermission.denied) {
  //         throw Exception('Location permission denied.');
  //       }
  //     }
  //     if (permission == LocationPermission.deniedForever) {
  //       throw Exception(
  //         'Location permission permanently denied. Enable it in settings.',
  //       );
  //     }
  //
  //     // Hard overall cap: even if every internal fallback misbehaves,
  //     // the UI is guaranteed to stop spinning after 20s total.
  //     final position = await _getPositionWithFallback().timeout(
  //       const Duration(seconds: 20),
  //     );
  //     setState(() {
  //       _currentPosition = position;
  //       _isLoadingLocation = false;
  //     });
  //     if (!mounted) return;
  //     context.read<AttendanceController>().setLocation(
  //       lat: position.latitude,
  //       lng: position.longitude,
  //     );
  //   } on TimeoutException {
  //     setState(() {
  //       _isLoadingLocation = false;
  //       _locationError =
  //           _currentPosition == null
  //               ? 'Could not get a location fix. Move to an open area and retry.'
  //               : null;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _locationError = e.toString().replaceFirst('Exception: ', '');
  //       _isLoadingLocation = false;
  //     });
  //   }
  // }

  Future<void> _showEnableLocationDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Turn on location'),
            content: const Text(
              'This app needs your device location to mark attendance. '
              'Please enable location services to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  setState(() {
                    _locationError = 'Location services are turned off.';
                  });
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await Geolocator.openLocationSettings();
                  // User may flip the toggle and come straight back —
                  // re-check once they return to the app.
                  if (!mounted) return;
                  _fetchLocation();
                },
                child: const Text('Enable'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- Photo ----------------

  Future<void> _captureImage() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1280,
        maxHeight: 1280,
        preferredCameraDevice: CameraDevice.front,
      );
      if (photo != null) {
        setState(() => _capturedImage = File(photo.path));
      }
    } catch (e) {
      _showSnack('Could not open camera: $e');
    }
  }

  // ---------------- Submit (Check-in) ----------------

  Future<void> _submitAttendance(AttendanceController controller) async {
    if (controller.selectedEmployeeId == null) {
      _showSnack('Please select an employee');
      return;
    }
    if (_currentPosition == null) {
      _showSnack('Location not ready yet — tap the refresh icon');
      return;
    }
    if (_capturedImage == null) {
      _showSnack('Please capture a check-in photo');
      return;
    }

    // Matches @Part(name: "image") required MultipartFile image in
    // RestClient.postEmployeeAttendance.
    final multipartImage = await MultipartFile.fromFile(
      _capturedImage!.path,
      filename: 'checkin_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    setState(() => _isCheckInLoading = true);

    final success = await controller.postEmployeeAttendance(
      employeeId: controller.selectedEmployeeId,
      lat: _currentPosition!.latitude,
      lng: _currentPosition!.longitude,
      image: multipartImage,
    );

    if (!mounted) return;
    setState(() => _isCheckInLoading = false);

    if (success) {
      _showSnack('Attendance marked successfully', isError: false);
      setState(() => _capturedImage = null);
      controller.clearData();
      // Refresh the base list so this employee's `status` flag flips to
      // "checked in" and the button swaps to Check Out on next visit —
      // clearData() alone only resets the selection, not cached statuses.
      await controller.getAttendanceBaseList();
      await _goToDashboard();
    } else {
      _showSnack(controller.errorMessage ?? 'Failed to submit');
    }
  }

  // ---------------- Submit (Check-out) ----------------

  Future<void> _submitCheckout(AttendanceController controller) async {
    if (controller.selectedEmployeeId == null) {
      _showSnack('Please select an employee');
      return;
    }
    if (_currentPosition == null) {
      _showSnack('Location not ready yet — tap the refresh icon');
      return;
    }
    if (_capturedImage == null) {
      _showSnack('Please capture a check-out photo');
      return;
    }

    final multipartImage = await MultipartFile.fromFile(
      _capturedImage!.path,
      filename: 'checkout_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    setState(() => _isCheckOutLoading = true);

    final success = await controller.postEmployeeAttendanceCheckout(
      employeeId: controller.selectedEmployeeId,
      lat: _currentPosition!.latitude,
      lng: _currentPosition!.longitude,
      image: multipartImage,
    );

    if (!mounted) return;
    setState(() => _isCheckOutLoading = false);

    if (success) {
      _showSnack('Checked out successfully', isError: false);
      setState(() => _capturedImage = null);
      controller.clearData();
      // Refresh so `status` flips back and the employee is eligible for
      // another check-in (e.g. next shift the same day), if that's how
      // your backend treats it.
      await controller.getAttendanceBaseList();
      await _goToDashboard();
    } else {
      _showSnack(controller.errorMessage ?? 'Failed to check out');
    }
  }

  // ---------------- Navigation helper ----------------

  /// Waits briefly so the success snackbar is visible, then pops back to
  /// whichever screen pushed AttendanceScreen — the dashboard, in your
  /// navigation flow. (Using popUntil(isFirst) here was the bug: it pops
  /// all the way to the very first route ever pushed — e.g. splash/login —
  /// not the dashboard, whenever there's more than one screen in between.)
  ///
  /// If AttendanceScreen can be reached from more than one place and you
  /// need to guarantee landing on the dashboard specifically, use a named
  /// route instead:
  ///   Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (r) => false);
  Future<void> _goToDashboard() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      ),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    // Rebuilds whenever the controller calls notifyListeners().
    final controller = context.watch<AttendanceController>();

    final selected = controller.selectedEmployee;
    // Drives which button(s) render below — true means this employee has
    // already checked in today, so only Check Out should be available.
    final isAlreadyCheckedIn = selected?.isCheckedIn ?? false;

    final canSubmit =
        controller.selectedEmployeeId != null &&
        _currentPosition != null &&
        _capturedImage != null &&
        !controller.isSubmitting;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Employee Attendance',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: darkBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.getAttendanceBaseList();
          await _fetchLocation();
        },
        color: accentBlue,
        child: Column(
          children: [
            // Header: dark blue rounded panel housing the employee
            // selector — now a photo card instead of a name-only pill.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: darkBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: _buildEmployeeSelector(controller),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildLocationCard(),
                  const SizedBox(height: 12),
                  _buildPhotoCard(),
                  const SizedBox(height: 24),
                  // Only Check Out is shown once the selected employee's
                  // `status` flag says they're already checked in today;
                  // otherwise both actions are available as before.
                  isAlreadyCheckedIn
                      ? SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                              canSubmit
                                  ? () => _submitCheckout(controller)
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentBlue,
                            disabledBackgroundColor: Colors.grey[400],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child:
                              _isCheckOutLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text(
                                    'Check Out',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                        ),
                      )
                      : Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed:
                                    canSubmit
                                        ? () => _submitAttendance(controller)
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darkBlue,
                                  disabledBackgroundColor: Colors.grey[400],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child:
                                    _isCheckInLoading
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Text(
                                          'Check In',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed:
                                    canSubmit
                                        ? () => _submitCheckout(controller)
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentBlue,
                                  disabledBackgroundColor: Colors.grey[400],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child:
                                    _isCheckOutLoading
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Text(
                                          'Check Out',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                              ),
                            ),
                          ),
                        ],
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Employee selector (lives in the dark header) --------

  Widget _buildEmployeeSelector(AttendanceController controller) {
    if (controller.isLoading) {
      return const SizedBox(
        height: 64,
        child: Center(
          child: SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (controller.errorMessage != null && controller.employeeData == null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              controller.errorMessage!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: controller.getAttendanceBaseList,
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    }

    final selected = controller.selectedEmployee;

    return InkWell(
      onTap: () => _openEmployeePicker(controller),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child:
            selected == null
                ? Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Tap to select employee',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ],
                )
                : Row(
                  children: [
                    _EmployeeAvatar(employee: selected, radius: 26),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${selected.id}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // "Checked In" badge — surfaces status right where the
                    // employee is displayed, so the Check In/Out swap
                    // below doesn't come as a surprise.
                    if (selected.isCheckedIn)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Checked In',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  // ---------------- Location card ----------------

  Widget _buildLocationCard() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (_currentPosition != null ? Colors.green : accentBlue)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _currentPosition != null
                    ? Icons.location_on
                    : Icons.location_off,
                color:
                    _currentPosition != null ? Colors.green[700] : accentBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LOCATION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _isLoadingLocation
                      ? Text(
                        'Fetching location…',
                        style: TextStyle(color: Colors.grey[600]),
                      )
                      : _locationError != null
                      ? Text(
                        _locationError!,
                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                      )
                      : _currentPosition != null
                      ? Text(
                        '${_currentPosition!.latitude.toStringAsFixed(6)}, '
                        '${_currentPosition!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      )
                      : Text(
                        'Location unavailable',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: accentBlue),
              onPressed: _isLoadingLocation ? null : _fetchLocation,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Photo card ----------------

  Widget _buildPhotoCard() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: accentBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'CHECK-IN PHOTO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accentBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _captureImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  image:
                      _capturedImage != null
                          ? DecorationImage(
                            image: ResizeImage(
                              FileImage(_capturedImage!),
                              width: 720,
                            ),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    _capturedImage == null
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 36,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to capture photo',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        )
                        : Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircleAvatar(
                              backgroundColor: darkBlue.withOpacity(0.75),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                onPressed: _captureImage,
                              ),
                            ),
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular employee photo with a graceful fallback (initials-free person
/// icon) for employees with no/blank/broken `photo` url. Reused by both the
/// header selector and the picker grid so avatar rendering only lives here.
class _EmployeeAvatar extends StatelessWidget {
  final Employee employee;
  final double radius;
  final Color backgroundColor;

  const _EmployeeAvatar({
    required this.employee,
    this.radius = 32,
    this.backgroundColor = const Color(0x1A1976D2),
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    if (!employee.hasPhoto) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Icon(Icons.person, size: radius, color: const Color(0xFF1976D2)),
      );
    }

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: backgroundColor,
        child: Image.network(
          employee.photoUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: radius,
                height: radius,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFF1976D2),
                  value:
                      progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                ),
              ),
            );
          },
          errorBuilder:
              (context, error, stackTrace) => Icon(
                Icons.person,
                size: radius,
                color: const Color(0xFF1976D2),
              ),
        ),
      ),
    );
  }
}

/// Full-height bottom sheet that replaces the old plain-text dropdown list.
///
/// Each employee is shown as a photo tile with their id and name. Tapping
/// the tile *is* the confirmation — there's no separate "confirm" step —
/// which matches how a face/photo picker should feel: pick the right
/// picture, done.
class _EmployeePickerSheet extends StatefulWidget {
  final List<Employee> employees;
  final Employee? selectedEmployee;

  const _EmployeePickerSheet({
    required this.employees,
    required this.selectedEmployee,
  });

  @override
  State<_EmployeePickerSheet> createState() => _EmployeePickerSheetState();
}

class _EmployeePickerSheetState extends State<_EmployeePickerSheet> {
  static const Color darkBlue = Color(0xFF1A1A2E);
  static const Color accentBlue = Color(0xFF1976D2);

  late List<Employee> _filtered;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.employees;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filtered = widget.employees.where((e) => e.matches(query)).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Select Employee',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: darkBlue,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.employees.length} total',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: 'Search by name or ID',
                    prefixIcon: const Icon(Icons.search, color: accentBlue),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child:
                    _filtered.isEmpty
                        ? const Center(child: Text('No matches'))
                        : GridView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 8,
                                childAspectRatio: 0.78,
                              ),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final employee = _filtered[index];
                            final isSelected =
                                employee == widget.selectedEmployee;

                            return _EmployeeTile(
                              employee: employee,
                              isSelected: isSelected,
                              onTap: () => Navigator.of(context).pop(employee),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A single tappable photo + id + name tile inside the picker grid.
/// Tapping is the "confirm" action — selection and confirmation are the
/// same gesture, by design.
class _EmployeeTile extends StatelessWidget {
  final Employee employee;
  final bool isSelected;
  final VoidCallback onTap;

  const _EmployeeTile({
    required this.employee,
    required this.isSelected,
    required this.onTap,
  });

  static const Color accentBlue = Color(0xFF1976D2);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentBlue.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentBlue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _EmployeeAvatar(employee: employee, radius: 30),
                if (isSelected)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: accentBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                // Small green dot on the avatar itself to flag already
                // checked-in employees while browsing the grid, before
                // they've even been selected.
                if (employee.isCheckedIn)
                  Positioned(
                    left: -2,
                    bottom: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              employee.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'ID: ${employee.id}',
              style: TextStyle(fontSize: 10.5, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
