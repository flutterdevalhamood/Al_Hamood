import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/company_vehicle_controller.dart';
import 'package:sample/src/util/app_colors.dart';

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
                  // Filter Button
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
                  // Existing filter count display
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

          return _buildVehicleCard(vehicle, vehicleType);
        },
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle, String vehicleType) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // EXPIRY INFORMATION MOVED TO TOP - PRIMARY FOCUS
            if (vehicleType == '0')
              _buildExpirySection(
                expiryDate:
                    vehicle['Plate1MulkiyaExpiryDate']?.toString() ?? 'N/A',
                title: 'Mulkiya Expiry Date',
              )
            else
              _buildTruckTrailerExpirySection(
                truckExpiry:
                    vehicle['Plate1MulkiyaExpiryDate']?.toString() ?? 'N/A',
                trailerExpiry:
                    vehicle['Plate2MulkiyaExpiryDate']?.toString() ?? 'N/A',
              ),

            const SizedBox(height: 16),

            // Header with vehicle type indicator
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

            // Vehicle Information (without expiry info)
            if (vehicleType == '0')
              _buildSingleVehicleInfoWithoutExpiry(vehicle)
            else
              _buildTruckTrailerInfoWithoutExpiry(vehicle),

            const SizedBox(height: 16),

            // Project Information
            if (vehicle['project'] != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vehicle['project']['Name'] ?? 'Unknown Project',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSingleVehicleInfoWithoutExpiry(Map<String, dynamic> vehicle) {
    return Column(
      children: [
        // License Plate
        _buildLicensePlate(
          category: vehicle['plate_1_category']?.toString() ?? '',
          plateNumber: vehicle['PlateNo1']?.toString() ?? 'N/A',
          color: vehicle['plate_1_color']?.toString() ?? 'white',
          title: 'License Plate',
        ),

        const SizedBox(height: 12),

        // Vehicle Details Grid
        _buildVehicleDetailsGrid([
          _buildDetailItem(
            'Model Year',
            vehicle['plate_1_model_year']?.toString() ?? 'N/A',
            Icons.calendar_today,
          ),
          _buildDetailItem(
            'Vehicle Kind',
            vehicle['plate_1_vehicle_kind']?.toString() ?? 'N/A',
            Icons.directions_car,
          ),
        ]),

        const SizedBox(height: 12),

        // Chassis Number only
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.confirmation_number,
                color: Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chassis Number',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle['Plate1ChassisNumber']?.toString() ?? 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTruckTrailerInfoWithoutExpiry(Map<String, dynamic> vehicle) {
    return Column(
      children: [
        // Truck Information
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Truck (Primary Vehicle)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildLicensePlate(
                category: vehicle['plate_1_category']?.toString() ?? '',
                plateNumber: vehicle['PlateNo1']?.toString() ?? 'N/A',
                color: vehicle['plate_1_color']?.toString() ?? 'white',
                title: 'Truck Plate',
                compact: true,
              ),
              const SizedBox(height: 8),
              _buildVehicleDetailsGrid([
                _buildDetailItem(
                  'Model Year',
                  vehicle['plate_1_model_year']?.toString() ?? 'N/A',
                  Icons.calendar_today,
                  compact: true,
                ),
                _buildDetailItem(
                  'Vehicle Kind',
                  vehicle['plate_1_vehicle_kind']?.toString() ?? 'N/A',
                  Icons.directions_car,
                  compact: true,
                ),
              ]),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Trailer Information
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.rv_hookup, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Trailer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildLicensePlate(
                category: vehicle['plate_2_category']?.toString() ?? '',
                plateNumber: vehicle['PlateNo2']?.toString() ?? 'N/A',
                color: vehicle['plate_2_color']?.toString() ?? 'white',
                title: 'Trailer Plate',
                compact: true,
              ),
              const SizedBox(height: 8),
              _buildVehicleDetailsGrid([
                _buildDetailItem(
                  'Model Year',
                  vehicle['plate_2_model_year']?.toString() ?? 'N/A',
                  Icons.calendar_today,
                  compact: true,
                ),
                _buildDetailItem(
                  'Vehicle Kind',
                  vehicle['plate_2_vehicle_kind']?.toString() ?? 'N/A',
                  Icons.directions_car,
                  compact: true,
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpirySection({
    required String expiryDate,
    required String title,
  }) {
    final isExpired = _isDateExpired(expiryDate);
    final isExpiringSoon = _isExpiringSoon(expiryDate);
    final daysLeft = _getDaysLeft(expiryDate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpired || isExpiringSoon ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isExpired || isExpiringSoon
                  ? Colors.red[300]!
                  : Colors.green[300]!,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  isExpired || isExpiringSoon
                      ? Colors.red[100]
                      : Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExpired
                  ? Icons.error
                  : isExpiringSoon
                  ? Icons.warning
                  : Icons.check_circle,
              color:
                  isExpired || isExpiringSoon
                      ? Colors.red[600]
                      : Colors.green[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired ? 'Expired:' : 'Expires On:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatDate(expiryDate),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            isExpired || isExpiringSoon
                                ? Colors.red[700]
                                : Colors.green[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (daysLeft.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isExpired || isExpiringSoon
                                  ? Colors.red[100]
                                  : Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          daysLeft,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                isExpired || isExpiringSoon
                                    ? Colors.red[700]
                                    : Colors.green[700],
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
    );
  }

  Widget _buildTruckTrailerExpirySection({
    required String truckExpiry,
    required String trailerExpiry,
  }) {
    final truckExpired = _isDateExpired(truckExpiry);
    final truckExpiringSoon = _isExpiringSoon(truckExpiry);
    final trailerExpired = _isDateExpired(trailerExpiry);
    final trailerExpiringSoon = _isExpiringSoon(trailerExpiry);

    final truckDaysLeft = _getDaysLeft(truckExpiry);
    final trailerDaysLeft = _getDaysLeft(trailerExpiry);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            (truckExpired ||
                    truckExpiringSoon ||
                    trailerExpired ||
                    trailerExpiringSoon)
                ? Colors.red[50]
                : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              (truckExpired ||
                      truckExpiringSoon ||
                      trailerExpired ||
                      trailerExpiringSoon)
                  ? Colors.red[300]!
                  : Colors.green[300]!,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (truckExpired ||
                              truckExpiringSoon ||
                              trailerExpired ||
                              trailerExpiringSoon)
                          ? Colors.red[100]
                          : Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  (truckExpired || trailerExpired)
                      ? Icons.error
                      : (truckExpiringSoon || trailerExpiringSoon)
                      ? Icons.warning
                      : Icons.check_circle,
                  color:
                      (truckExpired ||
                              truckExpiringSoon ||
                              trailerExpired ||
                              trailerExpiringSoon)
                          ? Colors.red[600]
                          : Colors.green[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Mulkiya Expiry Dates',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Truck Expiry
          _buildExpiryRowEnhanced(
            truckExpired ? 'Expired' : 'Truck Expiry',
            truckExpiry,
            Icons.local_shipping,
            truckExpired || truckExpiringSoon ? Colors.red : Colors.green,
            truckDaysLeft,
          ),

          const SizedBox(height: 12),

          // Trailer Expiry
          _buildExpiryRowEnhanced(
            trailerExpired ? 'Expired' : 'Trailer Expiry',
            trailerExpiry,
            Icons.rv_hookup,
            trailerExpired || trailerExpiringSoon ? Colors.red : Colors.green,
            trailerDaysLeft,
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryRowEnhanced(
    String label,
    String date,
    IconData icon,
    MaterialColor color,
    String daysLeft,
  ) {
    return Row(
      children: [
        Icon(icon, color: color[600], size: 18),
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
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (daysLeft.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        daysLeft,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color[700],
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

  // New License Plate Widget with UAE-style design
  Widget _buildLicensePlate({
    required String category,
    required String plateNumber,
    required String color,
    required String title,
    bool compact = false,
  }) {
    Color plateColor = _getPlateColor(color);
    Color textColor = _getTextColor(color);

    return Column(
      children: [
        if (!compact)
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        if (!compact) const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 8 : 12,
          ),
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
            children: [
              // Category (like "AD 2")
              if (category.isNotEmpty)
                Text(
                  category,
                  style: TextStyle(
                    color: textColor,
                    fontSize: compact ? 20 : 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),

              // Plate Number
              Text(
                plateNumber,
                style: TextStyle(
                  color: textColor,
                  fontSize: compact ? 20 : 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              // UAE text (small)
              if (!compact)
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

  Widget _buildVehicleDetailsGrid(List<Widget> details) {
    return Wrap(spacing: 8, runSpacing: 8, children: details);
  }

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon, {
    bool compact = false,
  }) {
    return Container(
      width: compact ? 140 : 160,
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: compact ? 14 : 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 10 : 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryAndChassisInfo({
    required String expiryDate,
    required String chassisNumber,
  }) {
    final isExpired = _isDateExpired(expiryDate);
    final isExpiringSoon = _isExpiringSoon(expiryDate);

    return Column(
      children: [
        // Expiry Date
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isExpired
                    ? Colors.red[50]
                    : isExpiringSoon
                    ? Colors.orange[50]
                    : Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isExpired
                      ? Colors.red[300]!
                      : isExpiringSoon
                      ? Colors.orange[300]!
                      : Colors.green[300]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isExpired
                    ? Icons.error
                    : isExpiringSoon
                    ? Icons.warning
                    : Icons.check_circle,
                color:
                    isExpired
                        ? Colors.red[600]
                        : isExpiringSoon
                        ? Colors.orange[600]
                        : Colors.green[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mulkiya Expiry Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(expiryDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isExpired
                                ? Colors.red[700]
                                : isExpiringSoon
                                ? Colors.orange[700]
                                : Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Chassis Number
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.confirmation_number,
                color: Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chassis Number',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chassisNumber,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      if (dateString == 'N/A' || dateString.isEmpty) return 'N/A';

      // Handle special dates like "9999-09-09"
      if (dateString.startsWith('9999')) return 'No Expiry';

      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
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
        return '(${difference.abs()} days ago)';
      } else if (difference == 0) {
        return '(Today)';
      } else if (difference == 1) {
        return '(1 day left)';
      } else {
        return '($difference days left)';
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
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
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

                // Filter options
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

                // Bottom padding
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}
