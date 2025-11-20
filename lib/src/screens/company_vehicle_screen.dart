import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/company_vehicle_controller.dart';
import 'package:sample/src/util/app_colors.dart';
import 'package:sample/src/widgets/date_format.dart';
import 'package:sample/src/widgets/number_plate_responsive_text.dart';

class CompanyVehicleScreen extends StatefulWidget {
  const CompanyVehicleScreen({super.key});

  @override
  State<CompanyVehicleScreen> createState() => _CompanyVehicleScreenState();
}

class _CompanyVehicleScreenState extends State<CompanyVehicleScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanyVehicleController>().getCompanyVehicleData();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        context.read<CompanyVehicleController>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Company Vehicles',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Appcolors.darkBlue,
        elevation: 0,
        actions: [
          Consumer<CompanyVehicleController>(
            builder: (context, controller, child) {
              return Row(
                children: [
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.filter_list, color: Colors.white),
                        if (controller.selectedFilter != 'All Companies')
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed:
                        () => _showFilterBottomSheet(context, controller),
                  ),
                  if (controller.isFiltered ||
                      controller.selectedFilter != 'All Companies')
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[600],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${controller.filteredCount}/${controller.totalCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<CompanyVehicleController>(
        builder: (context, controller, child) {
          return Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Appcolors.darkBlue,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by plate number...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    suffixIcon:
                        controller.searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                controller.clearSearch();
                              },
                            )
                            : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    controller.searchCompanyVehicles(value);
                  },
                ),
              ),

              // Content Area
              Expanded(
                child:
                    controller.errorMessage != null
                        ? _buildErrorWidget(controller)
                        : controller.isLoading &&
                            (controller.companyVehicleData?.isEmpty ?? true)
                        ? const Center(child: CircularProgressIndicator())
                        : controller.companyVehicleData?.isEmpty ?? true
                        ? _buildEmptyState()
                        : _buildVehicleList(controller),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(CompanyVehicleController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.refreshData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Vehicles Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No company vehicles match your search criteria',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleList(CompanyVehicleController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.refreshData(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount:
            (controller.companyVehicleData?.length ?? 0) +
            (controller.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == (controller.companyVehicleData?.length ?? 0)) {
            return controller.isLoading
                ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
                : const SizedBox.shrink();
          }

          final vehicle = controller.companyVehicleData![index];
          final vehicleType = vehicle['type']?.toString() ?? '0';

          return _buildVehicleCard(vehicle, vehicleType, index);
        },
      ),
    );
  }

  Widget _buildVehicleCard(
    Map<String, dynamic> vehicle,
    String vehicleType,
    int index,
  ) {
    final isEvenIndex = index % 2 == 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: isEvenIndex ? Colors.white : Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CARD 1: Plate Numbers Row with Vehicle Type Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        vehicleType == '1'
                            ? Colors.orange[100]
                            : Colors.blue[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        vehicleType == '1'
                            ? Icons.fire_truck
                            : Icons.directions_car,
                        size: 16,
                        color:
                            vehicleType == '1'
                                ? Colors.orange[700]
                                : Colors.blue[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vehicleType == '1'
                            ? 'Truck + Trailer'
                            : 'Light Vehicle',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              vehicleType == '1'
                                  ? Colors.orange[700]
                                  : Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Plate Numbers in Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child:
                  vehicleType == '1'
                      ? Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Truck Plate',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vehicle['PlateNo1']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[300],
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trailer Plate',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vehicle['PlateNo2']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plate Number',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vehicle['PlateNo1']?.toString() ?? 'N/A',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
            ),

            const SizedBox(height: 16),

            // CARD 2: Number Plates Display
            if (vehicleType == '0')
              _buildLicensePlate(
                category: vehicle['plate_1_category']?.toString() ?? '',
                plateNumber: vehicle['PlateNo1']?.toString() ?? 'N/A',
                color: vehicle['plate_1_color']?.toString() ?? 'white',
              )
            else
              Column(
                children: [
                  _buildLicensePlate(
                    category: vehicle['plate_1_category']?.toString() ?? '',
                    plateNumber: vehicle['PlateNo1']?.toString() ?? 'N/A',
                    color: vehicle['plate_1_color']?.toString() ?? 'white',
                    label: 'Truck Plate',
                  ),
                  const SizedBox(height: 12),
                  _buildLicensePlate(
                    category: vehicle['plate_2_category']?.toString() ?? '',
                    plateNumber: vehicle['PlateNo2']?.toString() ?? 'N/A',
                    color: vehicle['plate_2_color']?.toString() ?? 'white',
                    label: 'Trailer Plate',
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // CARD 3: Vehicle Details with Expiry
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vehicleType == '0')
                    _buildSingleVehicleDetails(vehicle)
                  else
                    _buildTruckTrailerDetails(vehicle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleVehicleDetails(Map<String, dynamic> vehicle) {
    final expiryDate = vehicle['Plate1MulkiyaExpiryDate']?.toString() ?? 'N/A';
    final isExpired = _isDateExpired(expiryDate);
    final isExpiringSoon = _isExpiringSoon(expiryDate);

    return Column(
      children: [
        _buildDetailRow(
          'Vehicle Kind',
          vehicle['plate_1_vehicle_kind']?.toString() ?? 'N/A',
          Icons.directions_car,
        ),
        const Divider(height: 24),
        _buildDetailRow(
          'Model Year',
          vehicle['plate_1_model_year']?.toString() ?? 'N/A',
          Icons.calendar_today,
        ),
        const Divider(height: 24),
        _buildDetailRow(
          'Chassis Number',
          vehicle['Plate1ChassisNumber']?.toString() ?? 'N/A',
          Icons.confirmation_number,
        ),
        const Divider(height: 24),
        _buildDetailRow(
          'Mulkiya Expiry',
          formatDate(expiryDate),
          Icons.event_available,
          valueColor:
              isExpired || isExpiringSoon ? Colors.red[700] : Colors.green[700],
          badge: _getDaysLeft(expiryDate),
          badgeColor: isExpired || isExpiringSoon ? Colors.red : Colors.green,
        ),
        if (vehicle['project'] != null) ...[
          const Divider(height: 24),
          _buildDetailRow(
            'Project',
            vehicle['project']['Name'] ?? 'Unknown Project',
            Icons.business,
          ),
        ],
      ],
    );
  }

  Widget _buildTruckTrailerDetails(Map<String, dynamic> vehicle) {
    final truckExpiry = vehicle['Plate1MulkiyaExpiryDate']?.toString() ?? 'N/A';
    final trailerExpiry =
        vehicle['Plate2MulkiyaExpiryDate']?.toString() ?? 'N/A';

    final truckExpired = _isDateExpired(truckExpiry);
    final truckExpiringSoon = _isExpiringSoon(truckExpiry);
    final trailerExpired = _isDateExpired(trailerExpiry);
    final trailerExpiringSoon = _isExpiringSoon(trailerExpiry);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Truck Details
        Text(
          'TRUCK DETAILS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Vehicle Kind',
          vehicle['plate_1_vehicle_kind']?.toString() ?? 'N/A',
          Icons.local_shipping,
        ),
        const Divider(height: 20),
        _buildDetailRow(
          'Model Year',
          vehicle['plate_1_model_year']?.toString() ?? 'N/A',
          Icons.calendar_today,
        ),
        const Divider(height: 20),
        _buildDetailRow(
          'Chassis Number',
          vehicle['Plate1ChassisNumber']?.toString() ?? 'N/A',
          Icons.confirmation_number,
        ),
        const Divider(height: 20),
        _buildDetailRow(
          'Mulkiya Expiry',
          formatDate(truckExpiry),
          Icons.event_available,
          valueColor:
              truckExpired || truckExpiringSoon
                  ? Colors.red[700]
                  : Colors.green[700],
          badge: _getDaysLeft(truckExpiry),
          badgeColor:
              truckExpired || truckExpiringSoon ? Colors.red : Colors.green,
        ),

        const SizedBox(height: 24),

        // Trailer Details
        Text(
          'TRAILER DETAILS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.orange[700],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Vehicle Kind',
          vehicle['plate_2_vehicle_kind']?.toString() ?? 'N/A',
          Icons.rv_hookup,
        ),
        const Divider(height: 20),
        _buildDetailRow(
          'Model Year',
          vehicle['plate_2_model_year']?.toString() ?? 'N/A',
          Icons.calendar_today,
        ),
        const Divider(height: 20),
        _buildDetailRow(
          'Chassis Number',
          vehicle['Plate2ChassisNumber']?.toString() ?? 'N/A',
          Icons.confirmation_number,
        ),
        const Divider(height: 20),
        _buildDetailRow(
          'Mulkiya Expiry',
          formatDate(trailerExpiry),
          Icons.event_available,
          valueColor:
              trailerExpired || trailerExpiringSoon
                  ? Colors.red[700]
                  : Colors.green[700],
          badge: _getDaysLeft(trailerExpiry),
          badgeColor:
              trailerExpired || trailerExpiringSoon ? Colors.red : Colors.green,
        ),

        if (vehicle['project'] != null) ...[
          const Divider(height: 24),
          _buildDetailRow(
            'Project',
            vehicle['project']['Name'] ?? 'Unknown Project',
            Icons.business,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    String? badge,
    MaterialColor? badgeColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: valueColor ?? Colors.grey[800],
                      ),
                    ),
                  ),
                  if (badge != null && badge.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor?[100] ?? Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: badgeColor?[700] ?? Colors.grey[700],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLicensePlate({
    required String category,
    required String plateNumber,
    required String color,
    String? label,
    double fixedWidth = 320,
  }) {
    Color plateColor = _getPlateColor(color);
    Color textColor = _getTextColor(color);

    return Column(
      children: [
        if (label != null) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Center(
          child: Container(
            width: fixedWidth,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: plateColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black87, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (category.isNotEmpty) ...[
                      Flexible(
                        flex: 2,
                        child: buildResponsiveText(
                          text: category,
                          textColor: textColor,
                          maxFontSize: 22,
                          minFontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Flexible(
                      flex: category.isNotEmpty ? 5 : 7,
                      child: buildResponsiveText(
                        text: plateNumber,
                        textColor: textColor,
                        maxFontSize: 26,
                        minFontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'UAE',
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getPlateColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red[600]!;
      case 'green':
        return Colors.green[600]!;
      case 'blue':
        return Colors.blue[600]!;
      case 'yellow':
        return Colors.yellow[600]!;
      case 'orange':
        return Colors.orange[600]!;
      case 'purple':
        return Colors.purple[600]!;
      case 'black':
        return Colors.black87;
      case 'white':
      default:
        return Colors.white;
    }
  }

  Color _getTextColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'white':
      case 'yellow':
        return Colors.black87;
      default:
        return Colors.white;
    }
  }

  bool _isDateExpired(String dateString) {
    try {
      if (dateString == 'N/A' || dateString.isEmpty) return false;
      if (dateString.startsWith('9999')) return false;
      final date = DateTime.parse(dateString);
      return date.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  bool _isExpiringSoon(String dateString) {
    try {
      if (dateString == 'N/A' || dateString.isEmpty) return false;
      if (dateString.startsWith('9999')) return false;
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final thirtyDaysFromNow = now.add(const Duration(days: 30));
      return date.isAfter(now) && date.isBefore(thirtyDaysFromNow);
    } catch (e) {
      return false;
    }
  }

  String _getDaysLeft(String dateString) {
    try {
      if (dateString == 'N/A' || dateString.isEmpty) return '';
      if (dateString.startsWith('9999')) return '';
      final expiryDate = DateTime.parse(dateString);
      final today = DateTime.now();
      final difference = expiryDate.difference(today).inDays;

      if (difference < 0) {
        return '${difference.abs()} days ago';
      } else if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return '1 day left';
      } else {
        return '$difference days left';
      }
    } catch (e) {
      return '';
    }
  }

  void _showFilterBottomSheet(
    BuildContext context,
    CompanyVehicleController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: Colors.grey),
                      const SizedBox(width: 12),
                      const Text(
                        'Filter by Company',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (controller.selectedFilter != 'All Companies')
                        TextButton(
                          onPressed: () {
                            controller.setFilter('All Companies');
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.availableFilters.length,
                  itemBuilder: (context, index) {
                    final filter = controller.availableFilters[index];
                    final isSelected = controller.selectedFilter == filter;
                    final count = controller.getFilterCount(filter);

                    return ListTile(
                      leading: Radio<String>(
                        value: filter,
                        groupValue: controller.selectedFilter,
                        onChanged: (value) {
                          if (value != null) {
                            controller.setFilter(value);
                            Navigator.pop(context);
                          }
                        },
                        activeColor: Appcolors.darkBlue,
                      ),
                      title: Text(
                        filter,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Appcolors.darkBlue
                                  : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      onTap: () {
                        controller.setFilter(filter);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}
