import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart' show MultipartFile;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/attendance_controller.dart';

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
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EmployeeSearchSheet(employees: employees),
    );
    if (result != null) {
      // Adjust 'id' key if your API uses a different casing.
      controller.setSelectedEmployee(result['id'] as int?);
    }
  }

  String? _selectedEmployeeName(AttendanceController controller) {
    final id = controller.selectedEmployeeId;
    if (id == null) return null;
    final employees = controller.employeeData;
    if (employees == null) return null;
    for (final e in employees) {
      if (e['id'] == id) return e['Name'] as String?;
    }
    return null;
  }

  Future<Position> _getPositionWithFallback() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
    } on TimeoutException {
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 10),
        );
      } on TimeoutException {
        // Still nothing fresh — fall back to the last known fix, if any.
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return last;
        rethrow;
      }
    }
  }

  // ---------------- Location ----------------

  Future<void> _fetchLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are turned off.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission permanently denied. Enable it in settings.',
        );
      }

      final position = await _getPositionWithFallback();
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
      if (!mounted) return;
      context.read<AttendanceController>().setLocation(
        lat: position.latitude,
        lng: position.longitude,
      );
    } catch (e) {
      setState(() {
        _locationError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingLocation = false;
      });
    }
  }

  // ---------------- Photo ----------------

  Future<void> _captureImage() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
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
            // Header: dark blue rounded panel housing the employee picker,
            // mirroring the search-bar treatment on the Swap Tyre list.
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
                  Row(
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
        height: 48,
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

    return InkWell(
      onTap: () => _openEmployeePicker(controller),
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline, color: Colors.white.withOpacity(0.85)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedEmployeeName(controller) ?? 'Select employee',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      controller.selectedEmployeeId == null
                          ? Colors.white.withOpacity(0.7)
                          : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.85)),
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

/// Bottom-sheet search picker — needed since the employee list can run
/// into the hundreds and a plain DropdownButton becomes unusable.
class _EmployeeSearchSheet extends StatefulWidget {
  final List<Map<String, dynamic>> employees;

  const _EmployeeSearchSheet({required this.employees});

  @override
  State<_EmployeeSearchSheet> createState() => _EmployeeSearchSheetState();
}

class _EmployeeSearchSheetState extends State<_EmployeeSearchSheet> {
  static const Color accentBlue = Color(0xFF1976D2);

  late List<Map<String, dynamic>> _filtered;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.employees;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filtered =
          widget.employees
              .where(
                (e) => (e['Name'] as String? ?? '').toLowerCase().contains(
                  query.toLowerCase(),
                ),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Employee',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by name',
                  prefixIcon: const Icon(Icons.search, color: accentBlue),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 8),
              Expanded(
                child:
                    _filtered.isEmpty
                        ? const Center(child: Text('No matches'))
                        : ListView.separated(
                          controller: scrollController,
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final employee = _filtered[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0x1A1976D2),
                                foregroundColor: accentBlue,
                                child: Icon(Icons.person, size: 20),
                              ),
                              title: Text(employee['Name'] as String? ?? ''),
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
